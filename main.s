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
	/* Set up the stack pointers for different cpu modes */
	
	mov r0, $0x11			@ Enter FIQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4200			@ set its stack pointer

	mov r0, $0x12			@ Enter IRQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4000			@ set its stack pointer
	
	
	mov r0, $0x13			@ Enter SWI mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4300			@ set its stack pointer

	mov r0, $0x17			@ Enter ABORT mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4400			@ set its stack pointer


	mov r0, $0x1b			@ Enter UNDEFINED mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4500			@ set its stack pointer

	mov r0, $0x10
	msr cpsr, r0			@ User mode | fiq/irq enabled
	mov sp, $0x8000
	
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

	ldr r0, =screenx			@ 1280
	ldr r1, =screeny			@ 720
	mov r2, $24
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
	mov r0, $0x01
	ldr r1, =Text1
	ldr r2, =Text1lng	
	bl _print_buffer

	/* display on screen Fabienne's picture. An intact bmp assembled into
	 * memory in imagedata.s file with the 1st 2bytes stripped to make
	 * restof header word aligned	*/
 _display_pic:
	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - offset that holds
						@  width and height
	mov r0, $0x500
	mov r1, $0x2d0

	rsb r6, r8, r0
	mov r6, r6, lsr $1			@ starting pixel location to
	rsb r7, r9, r1				@  display pic centre screen
	mov r7, r7, lsr $1			@  r6 - width, r7 - height
	add r7, r7, r9				@ bmp pics are bottom up
	ldr r11, [r10, $0x08]			@ offset that holds bitmap
						@  data offset.
	add r10, r10, r11			@ r10 holds start of pic loc
	add r8, r8, $1
	mov r12, r8				@ copy for counter of width
	mov r11, r6				@ copy starting point of width
_Lpic:
	ldrb r4, [r10], $1			@ easyier to ldr bytes with
	mov r0, r4				@  non word aligned data
	ldrb r4, [r10], $1
	orr r0, r4, lsl $8
	ldrb r4, [r10], $1
	orr r0, r4, lsl $16
	bl _fg_colour
	mov r0, r6				@ r6 and r7 are coordinates
	mov r1, r7
	bl _set_pixel

_Lwidth:
	subs r8, r8, $1				@ counter based on width
	addne r6, r6, $1
	moveq r6, r11				@ reset starting width if == 0
	moveq r8, r12
	subeq r7, $1
	subeqs r9, r9, $1			@ counter for height. if == 0
						@  then pic displayed
	bne _Lpic


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
/***************************************************************************
 *  Code used but no longer wanted that i've not brought myself to delete  *
_snow:
	mov r0, $360
	bl _random_numgen			@ get y
	mov r4,	r0				@ preserve y to send
	mov r0, $640
	bl _random_numgen			@ get x
	mov r1, r4				@ restore y
	bl _set_pixel
	add r5, r5, $5
	mov r0, r5
	bl _fg_colour
	b _snow
****************************************************************************/
