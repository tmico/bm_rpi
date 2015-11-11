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

_XL:	@ Decided againt a loop to boost speed of execution. saves aprox 750 cycles per glyph
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



	/* binary to hex in assci converter. (uses BinHex lookup table)
	 * Returns ascii coded value in r0-r1 (lsbyte in lsreg)	As such
	 * it can return a max value of 0xFFFFFFFF which should be enough
	 * as the pi is a 32bit system there is nothing to be gained from
	 * from any higher value. value passed from r0 */
_bin_hex:
	stmfd sp!, {r8-r11}
	ldr r11, =BinHex
	mov r12, r0				@ copy to work from
	mov r3, $0xff000000			@ masking bits
_BH0:
	eor r1, r1
	mov r8, $24
	and r10, r12, r3
	ldrb r9, [r11, r10]
	orr r1, r1, r9, lsl r8
	subs r8, r8, $0x08
	movmi r0, r1
	movs r3, r3, lsr #4
	bcc _BH0
	ldmfd sp!, {r8-r11}
	
	
	.data
	.align 2
	.global SystemFont
SystemFont:
	.word	_u_vga16


BinHex:
	.byte '0', '1', '2', '3'
	.byte '4', '5', '6', '7'
	.byte '8', '9', 'A', 'B'
	.byte 'C', 'D', 'E', 'F'

EditUndo16:
	.incbin		"editundo.adapt16.psf"	@ Fonts created by Brian kent
						@  in psf format (bitmap) with
						@  the unicode table stripped
	
Uvga16:
	.incbin		"u_vga16.psf"


	.global CursorLoc			@ Cursor location stored in mem
CursorLoc:
	.word 0x10				@ x coordinate
	.word 0x10				@ y coordinate
	
	.global ScreenWidth
	.global CursorPos

ScreenWidth:	
	.word 0x74				@ 116 char wide based 
						@  on font width 11
CursorPos:
	.word 0x74

	.global Text1
	.global Text1lng 
Text1:
	.asciz "< Welcome to TMX O1 >"
	Text1lng = . - Text1

/* Terminal */
	.align 4
TerminalStart:
	.int TerminalBuffer			@ 1st char in buffer

TerminalEnd:
	.int TerminalBuffer			@ last char in buffer

TerminalView:
	.int TerminalBuffer			@ 1st char in buffer on screen

TerminalColour:
	.byte 0x0f

	.align 8

TerminalBuffer:
	.rept 116 * 45
	.byte 0x7f
	.byte 0x00
	.endr

TerminalScreen:
	.rept 116 * 90
	.byte 0x7f
	.byte 0x00
	.endr

	.align 2
	.global ScreenBuffer
ScreenBuffer:				@ screen buffer to send to framebuffer
	.rept 0xf00
	.byte 0x00
	.endr

