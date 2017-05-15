/*======================================================================
 * _sys_timer* - function that uses the raspi system timer		*
 * - a 2x32 bit register that increments by 1 every 1MHz		*
 * The raspi has no clock the system timer is its way to		*
 * keep the time.							*
 *======================================================================*
 * The Syetem timer provides 4 32bit timer channels and 1 64bit	free	*
 * running counter. Each channel has an output compare register which	*
 * which is compared against the least 32 bits of the counter. When the *
 * values match, the sustem timer generates a signal to indicate a match*
 * for the appropriate channel. This signal is then fed into the	*
 * interrupt controller. The interrupt service routine then reads the	*
 * output compare register and adds the appropriate offset for the next *
 * timer tick.								*
 * The base address for system timer is 0x20003000			*
 * Address	Size	Name		Description		Read or Write
 * 20003000	4	Control / Status				RW
 * 20003004	4	Counter	A LO counter increments at 1MHz.	R
 * 20003008	4	Counter	A HI counter increments at 1MHz.	R
 * 2000300C	4	Compare 0	0th Comparison register.	RW
 * 20003010	4	Compare 1	1st Comparison register.	RW
 * 20003014	4	Compare 2	2nd Comparison register.	RW
 * 20003018	4	Compare 3	3rd Comparison register.	RW 
 *=====================================================================*/

/*_sys_timer_single(TIME) where TIME is expressed in centiseconds. Takes  *
 *	value from r0. Max value of TIME is 4,294,96cs (2^32) 		  *
 *	(a max value of about 4,000 sec) If a longer timer is needed use  *
 *	_sys_timer_long(). R0 returns value of 0 when 'time has run down'*/


	.global _sys_timer_single
_sys_timer_single:
	ldr r3, =0x20003004			@ loading counterALO
	ldr r2, [r3]
	push {r4-r6, lr}
	ldr r6, =10000				@ convert to microsec
	mul r5, r0, r6
	add r1, r2, r5				@ timer set
	mov r0, #0				@ prepare return value
_Ltimer$:
	ldr r2, [r3]
	cmp r1, r2
	bhi _Ltimer$
	ldmlsfd sp!, {r4-r6, pc}		@ pop


/*==========================================================================
/*_arm_timer(value, pre-scaler) - funtion that uses the system clock as a ARM Timer.
  • There is only one timer.
  • It only runs in continuous mode.
  • It has a extra clock pre-divider register.
  • It has a extra stop-in-debug-mode control bit.
  • It also has a 32-bit free running counter.
  The clock from the ARM timer is derived from the system clock. This clock 
  can change dynamically e.g. if the system goes into reduced power or in low 
  power mode. Thus the clock speed adapts to the overal system performance 
  capabilities. For accurate timing it is recommended to use the system timers.
  The base address for the ARM timer register is 0x2000B000.
Address	offset 	Description
0x400		Load	set the time for the register to count down. 
0x404		Value	(R) value from load put here 
0x408		Control (See below)
0x40C		IRQ Clear/Ack (W) writing 1 clears IRQ pending
0x410		RAW IRQ	(R) shows status of IRQ pending 0-clear 1-set
0x414		Masked IRQ (R) logical AND of IRQ pending bit and IRQ enable bit
0x418		Reload same as load but waits for value to count down to 0 first
0x41C		Pre-divider (R/W) 10bit wide predivider
0x420		Free running counter

* Control Register
	bits	R/W	Function
	31:10		Unused in standerd 804 mode
	23:16	R/W	Free running counter pre-scaler C=sys_clock/pre-scaler+1
	15:10		Unused
	9	R/W	BMC mode: free running counter; 1=enabled, 0 disabled	
	8	R/W	BMC mode: debug mode keep running; 1=halted, 0 enabled
	7	R/W	Timer: 1=enable; 0=disable
	6		Unused
	5	R/W	Interupt: 1=enable; 0=disable
	4		Unused
	3:2	R/W	Pre-scale bits:
			00 : pre-scale is clock / 1 (No pre-scale)
			01 : pre-scale is clock / 16
			10 : pre-scale is clock / 256
			11 : pre-scale is clock / 1 (Undefined in 804)
	1	R/W	0 : 16-bit counters; 1 : 23-bit counter
	0		Unused
*/

	.global _set_arm_timer_irq		@ sets_interupt for program calling
_set_arm_timer_irq:		
	mov r3, $0x20000000			@ ldr base_address
	add r3, r3, $0xb000			@ quicker than, ldr 0x2000b000
	cmp r0, $0				@ non zero value sets interupt
	ldr r1, [r3, $408]
	orrne r1, r1, $0x20			@ set bit 5 to enable irq
	biceq r1, r1, $0x20			@ clear bit 5 to disable irq
	str r1, [r3, $408]
	bx lr
	
	.global _set_arm_timer
	/* _set_arm_timer([TIME]) in micro sec */
_set_arm_timer:
	mov r3, $0x20000000			
	add r3, r3, $0xb000			@ quicker than, ldr 0x2000b000
	mov r1, $0xf9				@ pre-divider = 249
	str r1, [r3, $0x41c]
	str r0, [r3, $0x400]			@ r0 holds TIME
	str r0, [r3, $0x418]			@ str in reload reg
	mov r2, $0xa2				@ bits to set n control reg
	str r2, [r3, $0x408]			@ control reg set
	bx lr


/* _sys_clock:
	Input: no input. 64bit (CLO and CHI) free running counter starts at poweron
	Output: R0, value of clo (lo 32bits)
		R1, value of chi (hi 32bits)
*/
	.global _sys_clock
_sys_clock:
	mov r2, $0x20000000
	add r2, r2, $0x3000			@ Base addr if timer is 0x20003000
	ldr r0, [r2, $4]			@ get counter LO
	ldr r1, [r2, $8]			@ get counter HI
	bx lr

