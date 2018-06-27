/* initialize all the peripherals that system will need. */

	.text
	.align 2
	.global _boot_seq
_boot_seq:	
	mov r11, lr				@ preserve lr

	/* Setup TLB's and configure p15 c2 and domains*/
	bl _mmu_tlb
	ldr r0, =Tlb_l1_base
/*	orr r0, r0, $0x2			@ set page table walk to S */
	orr r0, r0, $0x10			@ Outer cachable WT*/
	orr r0, r0, $0x1			@ inner cachablbe */
	mcr p15, 0, r0, c2, c0, 0 		@ write TBT regester 0
	mov r0, $0
	mcr p15, 0, r0, c2, c0, 2 		@ set control regester to SBZ
	mov r0, $0b1101 			@ damain 0 = client, 1 = manager
	mcr p15, 0, r0, c3, c0, 0		@ write to domain control reg
     
     /* Enable branch prediction and instruction cache in p15 */
	mrc p15, 0, r0, c1, c0, 0		@ read control reg of p15
	mov r1, $0x1800				@ bits 11 and 12 enable I and Z
	orr r0, r0, r1
	orr r0, r0, $0x1			@ Enable the mmu (M) **
	bic r0, r0, $0x2			@ Disable strict alignment (A)
	orr r0, r0, $0x4			@ Enable L1 data cache  ***/
/*	bic r0, r0, $0x4			@ Disable L1 data cache  ***/
	bic r0, r0, $0x80			@ Little endian system (B)
	bic r0, r0, $0x100			@ Disable system protection (S)
	bic r0, r0, $0x200			@ Disable rom protection (R)
	bic r0, r0, $0x2000			@ clear = low exception vector (V)
	orr r0, r0, $(1<<23)			@ Enable extented page table */ 
	mcr p15, 0, r0, c1, c0, 0		@ write to control reg of c15

     /* Set VBAR to zero (reset value) */
	mov r0, $0x0
	mcr p15, 0, r0, c12, c0, 0
	mov r0, $0x00
	mcr p15, 0, r0, c7, c7, 0		@ invalidate caches, flush btac

	/* Set up irq handlers... 
	   ...Clear all enable interupts first	*/
	mov r0, $0x20000000			@ Base irq address
	add r0, r0, $0xb000
	mvn r1, $0
	str r1, [r0, $0x21c]
	str r1, [r0, $0x220]
	str r1, [r0, $0x224]
	mov r1, $0
	str r1, [r0, $0x20c]			@ disable all FIQ

	/* arm timer */
	ldr r1, [r0, $0x218]			@ Only concerned with timer at this time
	orr r1, r1, $0x1
	str r1, [r0, $0x218]
	ldr r2, =_arm_timer_interupt		@ loading loc of label
	ldr r3, =IrqHandler
	str r2, [r3, $380]			@ timer handler has 95*4 offset

	/*  ---End of enable interupts--- */

	/* Turn on green led to inform user system is on */
	mov r0, $16				@ GPIO led pin 
	mov r1, $1				@ set to output
	bl _set_gpio_func 
	mov r0, $16
	mov r1, $0				@ turn off power turns on led
	bl _set_gpio

	/* Setup framebuffer -- 
	 * To use defaults set in framebuffer.s set r0 to zero.
	 * Otherwise r0 is virtual width, r1 virtual height and r2 is colour 
	 * depth  */
	mov r0, $1280				@ 1280
	mov r1, $720				@ 720
	mov r2, $32
	bl _init_framebuffer
	teq r0, $0				@ zero returned = error
	beq _error$

	/* setup uart and send welcome text and ascii art logo*/
	ldr r0, =Text1
	bl _uart_ctr
	ldr r0, =VirusAscii
	bl _uart_ctr

	/* getting framebuffer address to send via uart */
	bl _graphics_adr
	ldr r3, =GraphicsAdr			@ str GPU addr in r0
	ldr r1, [r3]				@ ldr the GPU adr
	ldr r0, =hfs				@ ldr hex format specifier
	bl _kprint				@ kprint will put it in StOut
	cmp r0, $0
	mov r0, r1
	bleq _uart_ctr

	/* set backgroung colour to black in frame buffer*/
	mvn r0, $0xff000000
	bl _fg_colour

	/* seting up timer (The interrupt handler makes green led blink */
	mov r0, $0x6a000			@ tiny fraction under 1/2 sec
	bl _set_arm_timer

	/* ---End of init peripheral--- */ 
	mov lr, r11
	bx lr

hfs:
	.asciz "Graphics address: %x\n"
Text1:	
        .asciz "\n< Welcome to VIRUS O1 >\n--- Writen in assembler ---\n--- Which is well cool!!! ---\n"
