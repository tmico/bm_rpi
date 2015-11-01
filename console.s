/*
 *
 */

	.text
	.align 2
	.global _print_buffer
	  
/* _print_buffer: for decoding the ascii string and selecting
 *	correct font. By default string will be	sent to stdout (screen).
 *
 *	arguments:-
 *			r0	destination output [1 - stdout]
 *			r1	string start addr
 *			r2	number of char
 *
 *	
*/
_print_buffer:
	teq r2, $0x00				@ Test for at least 1 char
	moveq r0, $0x01				@ return error
	bxeq lr

	stmfd sp!, {r4-r11, lr}			@ This section loads font to use
	ldr r12, =SystemFont			@  set in SystemFont. Each font
	ldr r11, [r12]				@  has its own optimized routine
	bx r11

_u_vga16:
	mov r5, r1				@ copy string addr
	ldr r11, =Uvga16
	add r11, r11, $0x30			@ offset to font data
	ldr r10, =CursorLoc
	ldrd r6, r7, [r10]
	ldrb r3, [r5], $0x01

_X1:
	subs r3, r3, $0x20			@ sync ascii no to glyph pos
	add r4, r11, r3, lsl #4			@ glyph addr
	mov r9, $0x04				@ y counter
_X2:
	ldr r10, [r4], $0x04
	rev r10, r10				@ rev; revers byte order in Rm
	mov r8, $0x04				@ 1/4 font y counter

_XL:
	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x00
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x01
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x02
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x03
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x04
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x05
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x06
	movcs r1, r7
	blcs _set_pixel

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x07
	movcs r1, r7
	blcs _set_pixel
_YL:
	subs r8, r8, $0x01			@ 1/4 font height counter 
	add r7, r7, $0x01
	bne _XL
	subs r9, r9, $0x01			@ reset x	
	bne _X2					@ next row

_X3:
	add r6, r6, $0x08			@ new cusor loc
	sub r7, r7, $0x10
	ldrb r3, [r5], $0x01
	teq r3, $0x00
	bne _X1
	ldr r10, =CursorLoc
	strd r6, r7, [r10]			@ update CursorLoc

	ldmfd sp!, {r4-r11, pc}			@ exit


	/* large fonts rarly used /
_Editundo24:
	movne r2, r3, lsl #5
	addne r0, r2, r3, lsl #4		@ mul by 0x30 to get glyph
	add r11, r11, r0			@ glyph addr 

_L4:	
	ldrh r9, [r11], $0x02			@ ldr row
	and r0, r9, $0xff			@ swapping lower bytes round
	mov r9, r9, lsr #8			@  due to endianess
	orr r9, r9, r0, lsl #8
	mov r8, r5				@ cp width for counter
	mov r10, r6				@ cp x position
	mov r9, r9, lsl #16

_xloop:
	movs r9, r9, lsl #1			@ tst if bit falls off	
	movcs r0, r10
	movcs r1, r7
	blcs _set_pixel
	add r10, r10, $0x01
	subs r8, r8, $0x01
	bne _xloop

_yloop:
	subs r4, r4, $0x01			@ font height counter
	addne r7, r7, $0x01			@ incr y to next row
	
	bne _L4					@ next row

_L5:
	pop {r2, r4-r12}
	add r6, r6, r5
	strd r6, r7, [r10]			@ update CursorLoc

	subs r2, r2, $0x01			@ next char or exit
	bne _L1

	cmp r8, $0x00
	bne _B0 
	ldmfd sp!, {r4-r11, pc}			@ exit

	/* 1st 0x1f charactor have no glyphs but do have funtions. Bellow 
	 * only CR, Tab, Delete are being delt with for time being
	 */

_special_char:

	.data
	.align 2
	.global SystemFont
SystemFont:
	.word	_u_vga16
