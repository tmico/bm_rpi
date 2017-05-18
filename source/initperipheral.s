	/* initialize all the peripherals that system will need. */

	.text
	.align 2
	.global _boot_seq
_boot_seq:	
	stmfd sp!, {lr}
	
	/* Set up irq handlers 
	   Clear all enable interupts first	*/
	mov r0, $0x20000000		@ Base irq address
	add r0, r0, $0xb000
	mvn r1, $0
	str r1, [r0, $0x21c]
	str r1, [r0, $0x220]
	str r1, [r0, $0x224]
	mov r1, $0
	str r1, [r0, $0x20c]		@ disable all FIQ
	/* arm timer */
	ldr r1, [r0, $0x218]		@ Only concerned with timer at this time
	orr r1, r1, $0x1
	str r1, [r0, $0x218]
	ldr r2, =_arm_timer_interupt	@ loading loc of label
	ldr r3, =IrqHandler
	str r2, [r3, $380]		@ timer handler has 95*4 offset
	/*	End of enable interupts		*/
	/* Turn on green led to inform user system is on */
	mov r0, $16				@ GPIO led pin 
	mov r1, $1				@ set to output
	bl _set_gpio_func 

	mov r0, $16
	mov r1, $0				@ turn off power turns on led
	bl _set_gpio

	/* seting up timer (The interrupt handler makes green led blink */

	mov r0, $0x6a000			@ tiny fraction under 1/2 sec
	bl _set_arm_timer

	/* setup uart and send welcome text */
	ldr r0, =Text1
	bl _uart_ctr

	ldr r0, =VirusAscii
	bl _uart_ctr

	/* Setup framebuffer
	 * To use defaults set in framebuffer.s set r0 to zero.
	 * Otherwise r0 is virtual width, r1 virtual height and r2 is colour 
	 * depth  */
	mov r0, $1280				@ 1280
	mov r1, $720				@ 720
	mov r2, $32
	bl _init_framebuffer
	teq r0, $0				@ zero returned = error
	beq _error$

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

	/* Display welcome text */
	ldr r1, =Text1
	ldr r2, =Text1lng
	bl _write_tfb

	cmp r0, $0
	blne _clrscr_dma0
	bl _display_tfb
	
	/* End of init peripheral. Continue with rest of boot */
	ldmfd sp!, {pc}

hfs:
	.asciz "Graphics address: %x\n"
