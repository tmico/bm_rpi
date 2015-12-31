	.section .init				@ initialize this section first

	.global _start
_start:
	/* Exception Vector Table for arm*/
	b _reset	@ 0x00 reset
	b _undefined	@ 0x04 undefined instruction
	b _swi		@ 0x08 softeare interupt or svr
	b _pre_abort	@ 0x0c
	b _data_abort	@ 0x10
	b _reserved	@ 0x14
	b _irq_interupt @ 0x18 IRQ's
_fiq_interupt:
	b _fiq_interupt @ 0x1c fast interupt code can run directly from here
			@ without need to branch.
	.global _reset
_reset:
	/* Enable branch prediction in System Control coprocessor (CP15)

	@ TODO
	/* Set up the stack pointers for different cpu modes */
	
	mov r0, $0x11			@ Enter FIQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf20000		@ set its stack pointer

	mov r0, $0x12			@ Enter IRQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf00000		@ set its stack pointer
	
	
	mov r0, $0x13			@ Enter SWI mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf30000		@ set its stack pointer

	mov r0, $0x17			@ Enter ABORT mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf40000		@ set its stack pointer


	mov r0, $0x1b			@ Enter UNDEFINED mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf50000		@ set its stack pointer

	mov r0, $0x10
	msr cpsr, r0			@ User mode | fiq/irq enabled
	mov sp, $0xf00000
	
	/*	Enable various interupts	*/
	mov r0, $0x20000000		@ Base address
	add r0, r0, $0xb000
	/* arm timer */
	ldr r1, [r0, $0x218]		@ Only concerned with timer at this time
	orr r1, r1, $0x1
	str r1, [r0, $0x218]
	ldr r2, =_arm_timer_interupt	@ loading loc of lable
	ldr r3, =IrqHandler
	str r2, [r3, $256]		@ timer handler has 256 offset
	/*	End of enable interupts		*/
	b _main

/*=========================================================================*/
	.section .text
	.section .main

_main:
	/* Turn on green led to inform user system is on */
	mov r0, $16				@ GPIO led pin 
	mov r1, $1				@ set to output
	bl _set_gpio_func 
	mov r0, $16
	mov r1, $0				@ turn off power turns on led
	bl _set_gpio
	
	/* To use defaults set in framebuffer.s set r0 to zero.
	 * Otherwise r0 is virtual width, r1 virtual height and r2 is colour 
	 * depth  */

	mov r0, $1280				@ 1280
	mov r1, $720				@ 720
	mov r2, $32
	bl _init_framebuffer
	teq r0, $0				@ zero returned = error
	beq _error$	

	/* getting framebuffer address to print to screen and send */
	bl _get_graphics_adr
	
	/* set backgroung colour to black in frame buffer*/
_set_fb_colour:
	mvn r0, $0xff000000
	bl _fg_colour

	/* seting up timer (The interrupt handler makes green led blink */
_init_arm_timer:
	mov r0, $0x6a000			@ tiny fraction under 1/2 sec
	bl _set_arm_timer

	/* Display welcome text */
	ldr r1, =Text1
	ldr r2, =Text1lng	
	ldr r3, =TermBuffer
_LA:
	ldrb r0, [r1], #1
	strb r0, [r3], #1
	subs r2, r2, $0x01
	bne _LA
	bl _print_string


	/* routine to move around the screen fabienne's pic*/
_L0:
	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - dimentions of pic
	rsb r6, r8, $0x500			@  to get range for x and y
	rsb r7, r9, $0x2b0			@ 720-32-height = range for y

_L1:
	mov r0, r7
	bl _random_numgen
	add r4, r0, $0x20
	mov r0, r6
	bl _random_numgen
	mov r1, r4

	bl _display_pic

	/* Attempt a dma transfer to clear screen */
	ldr r5, =SysTimer
_1:
	ldr r12, [r5]
	cmp r12, $0x08
	bmi _1	
	bl _init_dma0				@ clear screen
	eor r12, r12
	str r12, [r5]

	
	b _L1

_Bloop:						
	b _Bloop	@ Catch all loop

	.global _error$
_error$:
	mov r0, $16				@ GPIO led pin 
	mov r1, $1				@ set to output
	bl _set_gpio_func 
	mov r1, $0				@ turn off pin to turn on led
	bl _set_gpio
	b _Bloop

	.data
	.align 2
	.global SysTimer
SysTimer:
	.int 0x00

Stack2:
	.word 0x00
	.word 0x20
	.word 0xff
	.word 0xff
