/*TOD0
 *
 */

.text
	.align 2
	.global _write_tfb
	.global _display_tfb

_write_tfb:
	/* _write_tbf takes: r0 = file descriptor number (yet to be implented,
	  read as don't care)
	  r1: mem address of string to write to terminal via _display_tfb
	  r2: n.o chars to be printed
	  */

	tb .req r4				@ terminal buffer
	tc .req r5				@ terminal current line
	x .req r6				@ screen across
	nx .req r6				@ negative x				
	y .req r7				@ screen down
	in .req r1				@ pointer of string
	noc .req r2				@ n.o chars to write
	char .req r8				@ char loaded from string
	tba .req r9				@ termbuffer addr

	stmfd sp!, {r4 - r9}
	ldr tb, =TermBuffer
	ldr r12, =CursorLoc
	ldrd x, y, [r12]
	ldr r12, =TermCur
	ldr tc, [r12]

	ldrb char, [in], $1
	mov r12, $80				@ bytes per line
	sub y, y, $44				@ no of lines left.
 
	mla tba, tc, r12, x			@ char addr = curntline * 80 + x
	add tba, tba, tb
	rsb nx, x, $79				@ n.o spaces left
_WT0:	
	cmp char, $0x20
	strb char, [tba], $1
	bmi _non_write
	subs noc, noc, $1			@ string counter
	beq _zero
	subs nx, nx, $1
	ldrneb char, [in], $1
	bne _WT0
	b _next_line
_non_write:
	cmp char, $'\n'
	beq _next_line
	cmp char, $0x0
	beq _zero
_next_line:	
	add tc, tc, $0x1
	and tc, tc, $0x7f
	add y, y, $0x1
	mov nx, $79
	add tba, tb, tc, lsl $6
	add tba, tba, tc, lsl $4
	ldrb char, [in], $1
	b _WT0
_zero:
	cmp char, $0				@ ensure null terminator present
	movne char, $0
	strneb char, [tba]

	cmp y, $0
	movmi r0, $0
	bmi _exit0
	ldr r12, =TermEnd
	ldr r3, [r12]
	add r2, y, $0x01			@ TermEnd 1 line clear
	add r3, r3, r2
	and r3, r3, $0x7f
	str r3, [r12]
	ldr r2, =TermStart
	ldr r1, =TermCur
	ldr r12, =CursorLoc
	sub tc, r3, $45
	and tc, tc, $0x7f
	str tc, [r2]
	str tc, [r1]
	mov x, $0
	mov y, $0
	strd x, y, [r12]
	mov r0, $1				@ return 1 to refresh screen
	
_exit0:
	ldmfd sp!, {r4 - r9}
	bx lr

	.unreq tb
	.unreq tc
	.unreq x
	.unreq nx
	.unreq y
	.unreq in
	.unreq noc
	.unreq char
	.unreq tba
_display_tfb:			@ working code to start. TODO colour support
/* _display_tfb prints to terminal the content of TermBuffer within the range of
 *	TermScreen. TermScreen is what is displayed on screen but is
 *	itself just two pointers; a first line and last line that is to be 
 *	printed.
*/
	scratch .req r12
	tc .req r4				@ current line
	tb .req r5				@ termial buffer 
	x .req r6 				@ x [0-79]
	y .req r7				@ y [0-44]

	stmfd sp!, {r4 - r11, lr}
	ldr scratch, =TermCur
	ldr tc, [scratch]
	ldr scratch, =CursorLoc
	ldrd x, y, [scratch]
	ldr tb, =TermBuffer			@ Not content just address
	
	add r1, x, tc, lsl $6
	add r1, r1, tc, lsl $4			@ mem loc = tc * 80 + x
	ldrb r0, [tb, r1]!			@ note write back
_TB:	
	cmp r0, $0x20				@ tst for non printable char
	bmi _non_print
	mov r1, x, lsl $3			@ * 8 = pixel loc across	
	mov r2, y, lsl $4			@ * 16 = pixel loc down
	bl _print_to_screen
	add x, x, $1
	cmp x, $80
	beq _new_line
	ldrb r0, [tb, $1]!
	b _TB
_new_line:
	ldr tb, =TermBuffer			@ reset tb as its a cyclic buffer
	mov x, $0
	add y, y, $1
	add tc, tc, $1
	and tc, tc, $0x7f			@ current line is looping
	mov r1, tc, lsl $6
	add r1, r1, tc, lsl $4			@ mem loc = tc * 80 
	ldrb r0, [tb, r1]!			@ note write back
	b _TB
	
_non_print:
	cmp r0, $'\n'
	beq _new_line
	cmp r0, $0
	ldr scratch, =TermCur
	ldr r1, =CursorLoc
	str tc, [scratch]
	strd x, y, [r1]
	ldmfd sp!, {r4-r11, pc}

.unreq tc
.unreq tb
.unreq x 
.unreq y
.unreq scratch

_print_to_screen:
/* _print_to_screen: for decoding the ascii char and selecting
 *	correct font. By default char will be sent to stdout (screen).
*/
	gadr .req r8				@ glyph addr
	x .req r9				@ x coordinate
	y .req r10				@ y coordinate
	c16 .req r11				@ row counter 16 (down)
	char .req r4				@ char to be printed
	bmap .req r4				@ bitmap

/* in future additional routine to choose font placed here */
	push {r4, lr}
_u_vga16:
	ldr gadr, =Uvga16
	sub char, r0, $0x20
	mov c16, $0x10				@ 16 rows
	add gadr, gadr, $0x30			@ add offset to bitmaps

	add gadr, gadr, char, lsl #4
	ldrb bmap, [gadr], #1
	mov x, r1
	mov y, r2
_F2:
	movs bmap, bmap, lsl #24		@ endianes issue plus allows
	beq _F4					@  testing using N flag
	addmi r0, x, $0				@  the 8th shift is pointless
	movmi r1, y				@  as it will always be a '0'
	blmi _set_pixel32
						
	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $1
	movmi r1, y
	blmi _set_pixel32

	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $2
	movmi r1, y
	blmi _set_pixel32
	
	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $3
	movmi r1, y
	blmi _set_pixel32

	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $4
	movmi r1, y
	blmi _set_pixel32

	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $5
	movmi r1, y
	blmi _set_pixel32

	movs bmap, bmap, lsl #1
	beq _F4
	addmi r0, x, $6
	movmi r1, y
	blmi _set_pixel32

_F4:
	add y, y, $0x01				@ set coordinates for next row
	subs c16, c16, $1
	ldrneb bmap, [gadr], #1
	bne _F2

	pop {r4, pc}

.unreq char
.unreq x
.unreq y
.unreq gadr
.unreq bmap
.unreq c16

	.DATA
	.align 2

	.global SystemFont
SystemFont:
	.word _u_vga16
	
EditUndo16:
	.incbin	"editundo.adapt16.psf"		@ Fonts created by Brian kent
						@  in psf format (bitmap) with
						@  the unicode table stripped
Uvga16:
	.incbin	"u_vga16.psf"

	.global Text1
Text1:
	.asciz "< Welcome to VIRUS O1 >\n--- Writen in assembler ---\n--- Which is well cool!!! ---\n"

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
	.word 0x00				@ x coordinate
	.word 0x00				@ y coordinate
	
	.align 4
	.global TermBuffer
TermBuffer:
	.rept 80 * 128				@ 80 char by 128 lines. 
	.byte 0x00				@  128 = 0x80 which simplifies
	.endr					@  a roll over count 

	.global ScreenBuffer
ScreenBuffer:					@ gadr to use by dma_0 to clear
	.rept 0x1400				@  screen
	.byte 0x00
	.endr

	.align 10
	.global StdOut
StdOut:
	.rept 0x400				@ 1024 bytes reserved
	.byte 0x0
	.endr
