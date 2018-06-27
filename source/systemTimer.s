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

/*_arm_timer(value, pre-scaler) - funtion that uses the system clock as a ARM Timer.*/
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

