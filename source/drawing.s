	.section .data
	.align 2
	.global FgColour
FgColour:
	.word 0xffffffff

	.global GraphicsAdr
GraphicsAdr:
	.word

	.section .text

	.global _fg_colour
_fg_colour:
	ldr r1, =FgColour
	str r0, [r1]				@ skip tesing as unnecessary
	bx lr

	.global _graphics_adr
_graphics_adr:
	/* In: r0 GPU pointer from FramebufferInfo */
	ldr r3, =FramebufferInfo
	ldr r1, =GraphicsAdr
	ldr r0, [r3, $32]
	str r0, [r1]
	bx lr

/*_set_pixel24: sends to the memory address of FB the pixel colour value
 * In: r0 X axis value, r1 the Y axis value.
 */
	.global _set_pixel24
_set_pixel24:
	stmfd sp!, {r4-r5, lr}			@ push
	ldr r2, =FramebufferInfo		@ check that x and y are valid
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

/*_set_pixel32: sends to the memory address of FB the pixel colour value
 * In: r0 X axis value, r1 the Y axis value.
 */
	.global _set_pixel32
_set_pixel32:
	ldr r12, =FramebufferInfo		@ check that x and y are valid
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

/*_set_pixel16: sends to the memory address of FB the pixel colour value
 * In: r0 X axis value, r1 the Y axis value.
 */
	.global _set_pixel16
_set_pixel16:
	ldr r3, =FramebufferInfo		@ original code that only 
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

	.global _draw_char
_draw_char:
	stmfd sp!, {r4,r5,r10}
	ldr r4, =FramebufferInfo		@ Get n.o pixels across
	ldr r12, =GraphicsAdr
	mov r3, r3, lsl $4			@ r3 = y pixel line number
	ldr r5, [r4]				@ r5 = pixels per line
	mov r2, r2, lsl $3			@ r2 = x pixels across
	ldr r4, [r12]				@ r4 = gpu frambuffer adr

	ldr r10, =cga_16color			@ 16 colour code table
	mla r12, r3, r5, r2			@ r12 = framebuffer pixel offset

	and r1, r0, $0xf00
	mov r1, r1, lsr $8			@ fg colour
	and r2, r0, $0xf000
	mov r2, r2, lsr $12			@ bg colour
	ldr r1, [r10, r1]
	ldr r2, [r10, r2]
		
	ldr r3, =Uvga16
	sub r0, r0, $0x20			@ glyph offset = ascii - 0x20
	add r12, r12, r4			@ r12 = pixel gpu addr= 

	ldrb r10, [r3, r10]!			@ load 1st line of bitmap
	mov r4, $16				@ n.o of lines loop

	/* r0=scratch, r1=fg, r2=bg, r3=glyph addr, r4=line counter, 
	   r5=pixel/line, r12=pixel addr */
_read_bit_loop:
	tst r10, $0x80
	strne r2, [r12]
	streq r1, [r12]
	tst r10, $0x40
	strne r2, [r12, $4]
	streq r1, [r12, $4]
	tst r10, $0x20
	strne r2, [r12, $8]
	streq r1, [r12, $8]
	tst r10, $0x10
	strne r2, [r12, $12]
	streq r1, [r12, $12]
	tst r10, $0x08
	strne r2, [r12, $16]
	streq r1, [r12, $16]
	tst r10, $0x04
	strne r2, [r12, $20]
	streq r1, [r12, $20]
	tst r10, $0x02
	strne r2, [r12, $24]
	streq r1, [r12, $24]
	tst r10, $0x01
	strne r2, [r12, $28]
	streq r1, [r12, $28]

	subs r4, r4, $1
	addne r12, r12, r5, lsl $2		@ Adjust pixel addr to nxt line
	ldrneb r10, [r3, $1]!
	bne _read_bit_loop

	ldmfd sp!, {r4,r5,r10}
	bx lr

	.data
	.align 2
Uvga16:
	.incbin "u_vga16.psf"
