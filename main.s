	.section .init				@ initialize this section first
_reloc_exeption_image:
	.word 0xe59ff018		@ = ldr pc, [pc, #24]
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
reset_h:
	.word _reset
undefined_h:
	.word _undefined
swi_h:
	.word _swi
pre_abort_h:
	.word _pre_abort
data_abort_h:
	.word _data_abort
reserved_h:
	.word _reserved
irq_h:
	.word _irq_interupt
fiq_h:
	.word _fiq_interupt

	.section .main

	.global _start
_start:
	b _main

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
	/* seting up timer (The interrupt handler makes green led blink */

	mov r0, $0x6a000			@ tiny fraction under 1/2 sec
	bl _set_arm_timer

	/* setup uart and send welcome text */
_uart_print:
	ldr r0, =VirusAscii
	bl _uart_t
	cmn r0, $1
	beq _error$

	ldr r0, =Text1
	bl _uart_t
	cmn r0, $1
	beq _error$

@	bl _rxtx_char


_setup_framebuffer:
	/* To use defaults set in framebuffer.s set r0 to zero.
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
	bleq _uart_t
	bl _rxtx_char

	/* set backgroung colour to black in frame buffer*/
_set_fb_colour:
	mvn r0, $0xff000000
	bl _fg_colour

	/* Display welcome text */
	ldr r1, =Text1
	ldr r2, =Text1lng
	bl _write_tfb

	cmp r0, $0
	blne _clrscr_dma0
	bl _display_tfb

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
	


	/* dma transfer to clear screen */
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
	mov r0, $0x2a000			
	bl _set_arm_timer

	b _Bloop
hfs:
	.asciz "%x\n"

	.data
	.align 2
	.global SysTimer
SysTimer:
	.int 0x00

