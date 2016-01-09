/* drawing.s holds these functions:
 *	_fg_colour : gets and stores  pixel color value at address FgColour

 *	_get_graphics_adr :  gets the address of the frambuffer pointer and 
				stores it at address GraphicsAdr

 *	_set_pixel16: sends to the memory address of FB the pixel colour value
		to be 'printed'.  
		recieves in r0 X axis value and in r1 the Y axis value.
		Co-ordinates (0,0) is top left of the screen. The values in r0
		and r1, are first checked against the width and height of the
		virtual screen loaded from address gotton from _get_graphics_adr
		the address offset for virtual width and hieght is #8 and #12
		respectfully. (see framebuffer.s)
		The memmory address for the pixel to set is its bit value long. 
		memory of _set_pixel = (virtual_width x Y) + X x nbytes 
		nbytes is the number of bytes used to store the colour. 16bit
		colour then has a value of 2bytes. X and Y start from 0

 *	_set_pixel: is for 24bit colours. It performs same function as above
		Coordinates of the pixel is calculated the same way where
		'nbytes' would be 3 rather than 2 as in 16bit colour. Being
		24bits or 3 bytes the memory locations are NOT word aligned
		it is therefor easier to write the individual 'r' 'g' 'b' 
		byte components that make up the colour at the address
		calculate + respective rgb_channel (0 red; 1 green; 2 blue)
		so for example we have colour value 0x00ffaa22
		in 16bit order the 'ff' is the red; 'aa' the green; '22' the blue
		supose we want to write this 24bit colour at address
		'GraphicsAdr+coordinate'; then we write the blue value {22} to 
		'GraphicsAdr+coordinate' + 2
		the green value {aa} to 'GraphicsAdr+coordinate' + 1
		the red value {ff} to 'GraphicsAdr+coordinate' + 0

============================================================================*/

	.section .data
	.align 2
	.global FgColour
FgColour:
	.word 0xffffffff

	.align 4
	.global GraphicsAdr
GraphicsAdr:		@ copy of framebuffer_info incase we don't want stdout
.int 640		@ #0 Physical Width (for my monitor)
.int 360		@ #4 Physical Hieght
.int 640		@ #8 eg Virtual Width
.int 360		@ #12 eg Virtual Hieght
.int 0			@ #16 GPU Pitch, GPU will fill it. no bytes per row
.int 24			@ #20 bit depth
.int 0			@ #24 X offsets (pixils to skip in top left corner)
.int 0			@ #28 Y
.int 0			@ #32 GPU Pointer
.int 0			@ #36 GPU Size

	.section .text

	.global _fg_colour
_fg_colour:
	ldr r1, =FgColour
	str r0, [r1]				@ skip tesing as unnecessary
	bx lr

	.global _get_graphics_adr
_get_graphics_adr:
	stmfd sp!, {r4-r11}			@ push
	ldr r1, =GraphicsAdr
	ldmia r0, {r2-r11}			@ mov GPU FB address to here
	stmia r1, {r2-r11}
	ldmfd sp!, {r4-r11}
	bx lr

	.global _set_pixel24
_set_pixel24:
	stmfd sp!, {r4-r5, lr}			@ push
	ldr r2, =GraphicsAdr			@ check that x and y are valid
	ldrd r4, r5, [r2, #8]			@ virt values of width, hieght
	cmp r0, r4				@  to cmp against
	cmpls r1, r5
	ldmhifd sp!, {r4-r5, pc}		@ pop and exit if out of range

	mla r3, r1, r4, r0			@ y * width + x
	ldr r0, [r2, #32]			@ GPU pointer
	add r3, r3, r3, lsl $1			@ x 3 for 24bit
	add r0, r0, r3				@ GPU base address + offset
	ldr r1, =FgColour			@  r0 = new mem loc 
	ldr r2, [r1]	
	strb r2, [r0]				@ red chanel
	mov r2, r2, lsr #8			@ mov green values to lsb
	strb r2, [r0, #1]			@ green channel
	mov r2, r2, lsr #8			@ mov blue values to lsb
	strb r2, [r0, #2]			@ blue channel

	ldmfd sp!, {r4-r5, pc}			@ pop and exit

	.global _set_pixel32
_set_pixel32:
	ldr r12, =GraphicsAdr			@ check that x and y are valid
	ldrd r2, r3, [r12, #8]			@ virt values of width, hieght
	cmp r0, r2				@  to cmp against
	cmpls r1, r3
	bxhi lr					@ pop and exit if out of range

	mla r3, r1, r2, r0			@ y * width + x
	ldr r0, [r12, #32]			@ GPU pointer
	ldr r1, =FgColour
	ldr r2, [r1]	
	add r0, r0, r3, lsl $2			@ x 4 for 32bit + GPU pointer
	orr r2, r2, $0xff000000			@ set alpha value
	str r2, [r0]

	bx lr

	.global _set_pixel16
_set_pixel16:
	ldr r3, =GraphicsAdr			@ original code that only 
	ldr r12, [r3]				@ would work for 16bit
	ldrd r2, r3, [r12, #8]			@ adr of virtual width, hieght
	cmp r0, r2
	cmpls r1, r3
	bxhi lr
	mla r3, r1, r2, r0			@ mem loc = width * Y + X
	ldr r0, [r12, #32]
	add r0, r0, r3, lsl $1			@ + offset
	ldr r1, =FgColour			@  r3 = new mem loc offset 
	ldr r2, [r1]	
	strh r2, [r0]
	bx lr					@ exit
