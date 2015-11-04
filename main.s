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
	mov sp, $0xf200			@ set its stack pointer

	mov r0, $0x12			@ Enter IRQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf000			@ set its stack pointer
	
	
	mov r0, $0x13			@ Enter SWI mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf300			@ set its stack pointer

	mov r0, $0x17			@ Enter ABORT mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf400			@ set its stack pointer


	mov r0, $0x1b			@ Enter UNDEFINED mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf500			@ set its stack pointer

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

	mov r0, $1280				@ 1280
	mov r1, $720				@ 720
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
