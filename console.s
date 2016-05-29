/*
 *
 */
	
.text
	.align 2
	.global _write_tfb
	.global _print_tfb 
	.global _kprint
	

_kprint:
/* _kprint funtion - converts values for printing according to args given
	and converts to ascii and stores in StdOut
	_kprint is a variadic function. As such arguments given to it are
	passed to it via the stack.
	befor args are pushed onto the stack the sp is copied to r0.
	r1 hold the addr of last arg on the stack. Thus r0 will be copied back
	to sp before returning from _kprint
	1st byte type	Meaning
		c	single char
		d	decimal int
		b	binary int
		f	float
		s	string
		x	hexadecimal
	2nd byte type	Meaning
		u	unsigned
		l	long
	
*/
	sps .req r4		@ sp pre args (spstart)
	spe .req r5		@ sp last arg

	stmfd sp!, {r4 - r11}
	mov sps, r0
	mov spe, r1

	ldmfd spe!, {r3}			@ 1st arg is 'header'
	and r2, r3, $0xf			@ issolate 1st byte to get type
	cmp r2, $'d'
	beq _intiger				@ Must be a better way than
	cmp r2, $'s'				@  endless cmp!
	beq _string
	cmp r2, $'c'
	beq _char
	cmp r2, $'f'
	beq _float
	cmp r2, $'x'
	beq _hex
	cmp r2, $'b'
_binary:	
_intiger:	
_string:	
_char:	
_float:	
_hex:	
	.unreq sps
	.unreq spe
_write_tfb:
	/*_write_tfb will take a string (ascii) passed stored in StdOut
	 *  of a mem address in r1, the number of chars to be printed in r2
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
	sub y, y, $44				@ no of lines left.
						 
	add tba, x, tc, lsl $6			@ tx * 80 + tc = tb char addr
	add tba, tba, tc, lsl $4 
	add tba, tba, tb
	rsb nx, x, $79				@ no spaces left
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
	cmp char, $0
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
_print_tfb:			@ Funtional code to start. TODO colour support
/* _print_tfb prints the content of TermBuffer within the range of
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
	mov r2, $31				/* Store multiple data in
						 * single registor to save having
						 * to push one on the stack
						 * The hi value is a counter
						 * Lo value is ascii '0'	*/

	mov r2, r2, lsl $16			@  as r2:lo holds value
	orr r2, r2, $0x30			@ ascii '0'
	mov r3, $0x31				@ ascii '1'
_BA:
	movs r0, r0, lsl #1			@ if cs then '1' else '0'
	strccb r2, [r12], #1
	strcsb r3, [r12], #1
	subs r2, r2, $(1<<16)
	bpl _BA
	sub r0, r12, $33			@ faster than ldr
	bx lr 

_bin_asciidec:
	/* Convert binary number (=< 32bits) into ascii decimal values */
	/* Toyed with idea of using double dabble method to get binary numbers
	 * stored in bcd format and then adding 0x30h to get ascii code for
	 * each 4bit bcd, but as much as i love the algorithm its way to slow
	 * for 32 bits so instead its div by 10, convert remainder to ascii
	 * store and repeat by div quotant and convert remainder.
	*/
	ldr r1, =0xcccccccd			@ 1/10 << 35
	ldr r12, =AsciiBcd 
_DA:	
	umull r2, r3, r0, r1
	mov r0, r3, lsr $3			@ move quotent back into r0
	and r3, r3, $7				@ isolate remainder 
	add r3, r3, lsl $2			@ r = r *5 << 3
	movs r3, r3, lsr $2			@ r = r*2 >>3
	movccs r2, r2, lsl $1			@ test if rounding correction needed 
	addcs r3, r3, $1			@ the remainder
	/* 'convert into ascii and store */
	add r3, r3, $0x30
	strb r3, [r12], $1
	cmp r0, $10
	bpl _DA
	add r0, r0, $0x30
	strb r0, [r12]
	ldr r0, =AsciiBcd
	bx lr
	
_bin_asciidec_long:	
	/* Convert a 64 bit binary number into ascii decimal values
	   This routine make use of the 'multiply long accumalate' op in the
	   arm11 unit. Neadless to say this is a time consumiing operation
	   r0 is lo; r1 is hi
	*/
	lo10	.req r2			@ reciprical lo
	hi10	.req r3			@ reciprical hi
	llo	.req r4			@ lo lo
	lhi	.req r5			@ lo hi
	hlo	.req r6			@ hi lo
	hhi	.req r7			@ hi hi
	scratch	.req r8			@ scratch
	
	stmfd sp!, {r4 -r8}
	ldr lo10, =0xcccccccd
	ldr r12, =AsciiBcd
	sub hi10, lo10, $0x1
	
	umull llo, lhi, r0, lo10
	mov hlo, $0
	umlal lhi, hlo, r0, hi10
	mov scratch, $0
	umlal lhi, scratch, r1, lo10
	mov hhi, $0
	adds hlo, hlo, scratch
	adc hhi, hhi, hhi
	umlal hlo, hhi, r1, hi10
	/* After the above routine the remainder is in
	llo lhi and least significant 3 bits of hlo.
	(you can imagine the point was between r5 r6 and has been << 3 places)
	*/
	and scratch, hlo, $0x7			@ Isolate remainder
	add scratch, scratch, scratch, lsl $2
	movs scratch, scratch, lsr $2
	movccs lhi, lhi, lsl $1			@ Correct rounding errors
	adc scratch, scratch, $0
	
	
	
	
	.data
	.align 2

AsciiBin:	
	.rept 0x20
	.byte 0
	.endr
AsciiBcd:
	.rept 0x16
	.byte 0
	.endr

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
StdOut:
	.rept 0x400				@ 1024 bytes reserved
	.byte 0x0
	.endr
