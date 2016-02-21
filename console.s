/*
 *
 */
	
.text
	.align 2
	.global _print_string
	.global _print_buffer 
	.global _printf
	

_kprint:
/* _kprint funtion - converts values for printing according to args given
	and converts to ascii and 'prints' to ScreenBuffer
*/

_print_buffer:			@ Funtional code to start. TODO colour support
/* _print_buffer prints the content of TermBuffer within the range of
 *	TermScreen. TermScreen is what is displayed on screen but is
 *	itself just two pointers; a first line and last line that is to be 
 *	printed.
 *	_print_buffer sends line by line the content of TermBuffer updating
 *	TermCur (current line), TermStart and TermEnd
*/
	stmfd sp!, {r4 - r8, lr}
	ldr r12, =TermStart			@ ldr buffer* var
	ldr r4, [r12]
	ldr r12, =TermEnd
	ldr r5, [r12]
	ldr r12, =TermCur
	ldr r6, [r12]
	ldr r7, =TermBuffer			@ Not content just address
	ldr r12, =CursorLoc
	ldr r8, [r12, #4]

	cmp r6, $45				@ tst if on bottom line
	bleq _scroll_page

_PB1:

	add r1, r4, r6				@ add line number to TermStart
	and r1, r1, $0x7f			@ mask to keep looping TermBuffer
	mov r0, r1, lsl $6
	add r0, r0, r1, lsl $4			@ mul by 80
	add r1, r7, r0				@ r1 points to loc in TermBuffer
	bl _print_string

	ldr r12, =CursorLoc
	cmp r0, $'\n'				@ new line then loop
	add r6, $1				@ next line
	add r8, r8, $0x16			@ next line
	str r8, [r12, #4]
	bne _exit0
	beq _PB1

	cmp r6, $45
	bmi _PB1

_scroll_page:
	push {lr}
	ldr r12, =TermStart
	addeq r4, r4, $1			@ if > scroll down buffer 
	andeq r4, r4, $0x7f			@ 0 - 127
	streq r4, [r12]

	ldr r12, =TermEnd
	addeq r2, r2, $1 
	andeq r2, r2, $0x7f
	streq r2, [r12]

	ldr r12, =TermCur
	mov r6, $0x0				@ reset curent line
	str r6, [r12]
	
	ldr r12, =CursorLoc
	mov r8, $0x00				@ mov CursorLoc back to top
	str r8, [r12, #4]

	bl _init_dma0				@ clear thte screen
	pop {pc}
	
_exit0:
	ldr r12, =TermStart			@ save buffer* var
	str r4, [r12]
	ldr r12, =TermEnd
	str r5, [r12]
	ldr r12, =TermCur
	str r6, [r12]
	ldr r12, =TermBuffer
	str r7, [r12]

	ldmfd sp!, {r4-r8, pc}			@ anything other then exit


_print_string:
/* _print_string: for decoding the ascii string and selecting
 *	correct font. By default string will be	sent to stdout (screen).
 *	_print_buffer passes the address of the start of the string in r1.
 *	_print string keeps on printing till a '\n' or 0x00 byte is met.
*/

	stmfd sp!, {r4-r11, lr}			@ This section loads font to use
	ldr r12, =SystemFont			@  set in SystemFont. Each font
	ldr r11, [r12]				@  has its own optimized routine
	bx r11
_u_vga16:
	mov r5, r1				@ copy string addr
	ldrb r0, [r5], $0x01
	ldr r11, =Uvga16
	ldr r10, =CursorLoc
	add r11, r11, $0x30			@ offset to font data
	ldrd r6, r7, [r10]
_X1:
	subs r3, r0, $0x20			@ sync ascii no to glyph pos
	bmi _special_char
	cmppl r3, $0x5e				@ tst valid ascii code
	ldmplfd sp!, {r4-r11, pc}
	add r4, r11, r3, lsl #4			@ glyph addr
	ldr r10, [r4], $0x04
	mov r9, $0x04				@ y counter

_X2:
	mov r8, $0x04				@ 1/4 font y counter
	rev r10, r10				@ rev; revers byte order in Rm
_XL:	@ Decided againt a loop to boost speed of execution. saves aprox 750 cycles per glyph
	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x00
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x01
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x02
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x03
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x04
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x05
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x06
	movcs r1, r7
	blcs _set_pixel32

	movs r10, r10, lsl #1			@ tst if bit falls off	
	addcs r0, r6, $0x07
	movcs r1, r7
	blcs _set_pixel32
_YL:
	subs r8, r8, $0x01			@ 1/4 font height counter 
	add r7, r7, $0x01
	bne _XL
	subs r9, r9, $0x01			@ reset x	
	ldrne r10, [r4], $0x04
	bne _X2					@ next row

_X3:
	ldrb r0, [r5], $0x01
	add r6, r6, $0x08			@ new cusor loc
	sub r7, r7, $0x10
	teq r0, $0x00
	teqne r0, $0x0a				@ tst for '\n'
	bne _X1

	ldmfd sp!, {r4-r11, pc}			@ exit


_special_char:
/* TODO*/
	ldmfd sp!, {r4-r11, pc}			@ exit

	
_bin_asciihex:
	/* binary to hex in assci converter. Converts value in r0 to hex
	 * Returns ascii coded value in r0-r1 (lsbyte in lsreg)	As such
	 * it can return a max value of 0xFFFFFFFF which should be enough
	 * as the pi is a 32bit system there is nothing to be gained from
	* from any higher value (for this very basic os!) */

	mov r12, r0				@ copy to work from
	
	eor r0, r0, r0
	eor r1, r1, r1
	mov r3, $0x04				@ 4 x loop counter
	
_BH0:
	and r2, r12, $0x0f
	cmp r2, $0xa
	addmi r2, r2, $0x30			@ if 0-9
	addpl r2, r2, $0x38			@ if 10-16
	orr r0, r0, r2
	ror r0, r0, $0x08			@ The author is proud of this little idea!!!

	mov r12, r12, lsr $4			@ shift down for nxt and
	subs r3, r3, $0x01
	bne _BH0
	mov r3, $0x04				@ 4 x loop counter
_BH1:						@ repeat of code but for
	and r2, r12, $0x0f			@  hi bits
	cmp r2, $0xa
	addmi r2, r2, $0x30			@ if 0-9
	addpl r2, r2, $0x38			@ if 10-16
	orr r1, r1, r2
	ror r1, r1, $0x08
	
	mov r12, r12, lsr $4
	subs r3, r3, $0x01
	bne _BH1
	bx lr

_bin_asciibin:	
	/* _bin_asciibin converts 1 word (4bytes) value into an ascii string
	 * of a binary number. The value to be converted is passed via r0.
	 * The return string being potentially too long to return in r0-r3 is
	 * instead passed via a pointer to a mem location (AsciiBin). R0 holds
	 * the pointer, r1 the n.o char in the string. The max being 32.   */
	ldr r12, =AsciiBin
	clz r1, r0
	rsb r1, r1, $32				@ n.o chars
	mov r2, r1				/* Store multiple data in
						 * single registor to save having
						 * to push one on the stack
						 * The hi value is a counter
						 * Lo value is ascii '0'	*/

	sub r2, r2, $1				@ countdown to negative not zero
	mov r2, r2, lsl $16			@  as r2:lo holds value
	orr r2, r2, $0x30			@ ascii '0'
	mov r3, $0x31				@ ascii '1'
_BA:
	movs r0, r0, lsr #1			@ if cs then '1' else '0'
	strcsb r3, [r12], #1
	strccb r2, [r12], #1
	subs r2, r2, $(1<<16)
	bpl _BA
	ldr r0, =AsciiBin
	bx lr 

/*============================================================================*/	
	.data
	.align 2
AsciiBin:	
	.rept 0x08
	.word 0
	.endr
	
	.global SystemFont
SystemFont:
	.word	_u_vga16


EditUndo16:
	.incbin	"editundo.adapt16.psf"		@ Fonts created by Brian kent
						@  in psf format (bitmap) with
						@  the unicode table stripped
Uvga16:
	.incbin	"u_vga16.psf"

	.global Text1
Text1:
	.asciz "< Welcome to VIRUS O1 >"

	.global Text1lng 
	Text1lng = . - Text1

	.global TermStart
TermStart:
	.int 0x00				@ 1st line in buffer

	.global TermEnd
TermEnd:
	.int 0x2d				@ 45 lines apart from TerminalStart

	.global TermCur
TermCur:
	.int 0x00				@ 1st line in buffer on screen

	.global TermColour
TermColour:
	.byte 0x00

	.align 3				@ 8 byte alignment for ldrd to work
	.global CursorLoc			@ Cursor location stored in mem
CursorLoc:
	.word 0x10				@ x coordinate
	.word 0x00				@ y coordinate
	
	.align 4
	.global TermBuffer
TermBuffer:
	.rept 80 * 128				@ 80 char by 128 lines. 
	.byte 0x00				@  128 = 0x80 which simplifies
	.endr					@  a roll over count 

	.global ScreenBuffer
ScreenBuffer:					@ tmp to use by dma_0 to clear
	.rept 0x1400				@  screen
	.byte 0x00
	.endr
