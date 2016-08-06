	.section .init				@ initialize this section first
/*
	Instruction table to load into memory 0x00
	The kernel is loaded to mem loc 0x8000. The arm system jumps to these
	addresses when there is an exception:
	0x00 : reset
	0x04 : undifined instruction
	0x08 : software interupt (svr)
	0x0c : pre abort
	0x10 : data abort
	0x14 : reserverd
	0x18 : IRQ
	0x1c : FIQ
	The insruction table is used to put the correct branch instructions 
	(ie, if there is an interupt, the intruction at 0x18 will be
	[b <_interupt_handler_lable>])
	into the correct memory location
*/

	/* Relocate Exception_Instructions table to start of mem */
	ldr r3, =Exception_Instruction
	mov r0, $0x0
	ldr r2, [r3]
	str r2,  [r0]				@ reset

	ldr r2, [r3, $0x04]
	str r2, [r0, $0x04]			@ undefined

	ldr r2, [r3, $0x08]
	str r2, [r0, $0x08]			@ svr

	ldr r2, [r3, $0x0c]
	str r2, [r0, $0x0c]			@ pre abort

	ldr r2, [r3, $0x10]
	str r2, [r0, $0x10]			@ data abort

	ldr r2, [r3, $0x14]
	str r2, [r0, $0x14]			@ resered

	ldr r2, [r3, $0x18]
	str r2, [r0, $0x18]			@ IRQ

	ldr r2, [r3, $0x1c]
	str r2, [r0, $0x1c]			@ FIQ

	b _start
Exception_Instruction:				@ instruction to be relocated
	b _reset		@ 0x00 reset
	b _undefined		@ 0x04 undefined instruction
	b _swi			@ 0x08 software interupt
	b _pre_abort		@ 0x0c
	b _data_abort		@ 0x10
	b _reserved		@ 0x14
	b _irq_interupt		@ 0x18
	b _fiq_interupt		@ 0x1c TODO run direct from this address

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
