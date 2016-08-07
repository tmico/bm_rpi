	.section .init				@ initialize this section first
	bl _relocate_exception_vector		@ set up exception vector table
	b _start
	.global _start
_start:
	b _reset					@ reset sets up i and d
							@  cache and other stuff

	.section .main
	.global _main

_main:
	/* Turn on green led to inform user system is on */
	mov r0, $16				@ GPIO led pin 
	mov r1, $1				@ set to output
	bl _set_gpio_func 
	mov r0, $16
	mov r1, $0				@ turn off power turns on led
	bl _set_gpio

_init_arm_timer:
	mov r0, $0x6a000			@ tiny fraction under 1/2 sec
	bl _set_arm_timer

	/* To use defaults set in framebuffer.s set r0 to zero.
	 * Otherwise r0 is virtual width, r1 virtual height and r2 is colour 
	 * depth  */
	mov r0, $1280				@ 1280
	mov r1, $720				@ 720
	mov r2, $32
	bl _init_framebuffer
	teq r0, $0					@ zero returned = error
	beq _error$

	/* getting framebuffer address to print to screen and send */
	bl _get_graphics_adr

	/* set backgroung colour to black in frame buffer*/
_set_fb_colour:
	mvn r0, $0xff000000
	bl _fg_colour

	/* seting up timer (The interrupt handler makes green led blink */

	/* Display welcome text */
	ldr r1, =Text1
	ldr r2, =Text1lng
	bl _display_tfb

	cmp r0, $0
	blne _clrscr_dma0
	bl _display_tfb				@ Funtional _print_buffer

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
/*	
	ldr r5, =SysTimer
_1:
	ldr r12, [r5]
	cmp r12, $0x08
	bmi _1	
	bl _clrscr_dma0				@ clear screen
	eor r12, r12
	str r12, [r5]

	
	b _L1
	*/
_Bloop:						
	b _Bloop	@ Catch all loop

	.global _error$
_error$:
	mov r0, $0x3a000			
	bl _set_arm_timer

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
