
	.text
	.align 2
	.global _kprint

_kprint:
/*	Input:	r0 string address
		r1 - r3 interger, character (ascii), address of string (pointer)
		stack additional args (int, char, string address)
	Output: r0 0 success; -1 failure
		r1 StdOut

	_kprint funtion - converts values for printing according to args given
	and converts to ascii and stores in StdOut (Max size of StdOut is 1024 char)
	_kprint is a variadic function.
	place holder	Meaning
		%c	single char
		%d	decimal int
		%b	binary int
		%f	float  ---> not yet implemented
		%s	string
		%x	hexadecimal
		%u	unsigned
		%l	long (64 bit)

*/
_kprint:	
	stmfd sp!, {r3}				@ str args for easy access
	stmfd sp!, {r2}				@ str args for easy access
	stmfd sp!, {r1}				@ str args for easy access
	stmfd sp!, {r4 - r10, lr}
	ldrb r4, [r0], $1
	ldr r5, =StdOut
	mov r6, r0				@ copy addr of string input
	mov r7, $1024				@ max char length counter
	add r10, sp, $32			@ set fp for args if any

_parse:
	teq r4, $'%'				@ '%' a la printf()
	beq _forsp				@ FORmatSPecifier
	teq r4, $0					@ NULL terminator
	strneb r4, [r5], $1			@ strb to StdOut
	subnes r7, r7, $1
	ldrneb r4, [r6], $1
	bne _parse
	b _str_end


_forsp:
	ldrb r4, [r6], $1
	ldr r0, =Jumptable
	mov r9, $0				@ deleting stale values
	mov r8, $0				@ deleting stale values
	mov r1, $10				@ convert from binary to bcd
	/* This looks terrible and there's probably a better way but brain dead!
	   chunk of code checks char after the '%' placeholder to assertain if
	   width (0 or space) is required. problem lies that ascii numbers are
	   bang in middle between some symbols and alpha char's. */
_for0:
	/* below is a switch(c) block of code */
	cmp r4, $0x39
	bic r3, r4, $0xe0			@ clear to 'switch' case of char
	addls pc, pc, $0x14
	mov r1, r3, lsl $2			@ * 4 to word align
	add r1, r1, r0
	ldr r2, [r1]				@ branch to correct %d,b,x
	ldmfd r10!, {r0}
	ldr lr, =_ins_var
	bx r2

	subs r2, r4, $0x30			@ block decides on space or 0
	bmi _for1
	mla r3, r1, r8, r2			@ convert ascii to binary
	cmpeq r9, $0				@ r9 will hold ' ' or '0'
	moveq r9, $'0'
	cmp r9, $0
	moveq r9, $' '
	mov r8, r3				@ preserve for next loop
	ldrb r4, [r6], $1
	b _for0

	.data
	.align 2
	/* non global jump table to deal with the switch involved in type of
	 * format after the '%' placeholder. takes up more space but less clunky
	 * than endless cmp instructions.
	*/
Jumptable:
	.word	 _for2 @0
	.word	 _for2 @a
	.word	_binary
	.word	_char
	.word	_integer
	.word	_for2 @e
	.word	_for2 @f
	.word	_for2 @g
	.word	_for2 @h
	.word	_for2 @i
	.word	_for2 @j
	.word	_for2 @k
	.word	_for2 @l
	.word	_for2 @m
	.word	_for2 @n
	.word	_for2 @o
	.word	_for2 @p
	.word	_for2 @q
	.word	_for2 @r
	.word	_string @s
	.word	_for2 @t
	.word	_for2 @u
	.word	_for2 @v
	.word	_for2 @w
	.word	_hex  @x
	.word	_for2 @y
	.word	_for2 @z
	.word	_for2 @
	.word	_for2 @
	.word	_for2 @
	.word	_for2 @

	.text
	.align 2

_for1:
	strb r4, [r5], $1
	subs r7, r7, $1				@ adjust remaining space on StdOut
	ldrneb r4, [r6], $1			@ get new char
	bne _parse
	b _str_end

_for2:						@ going back to _parse
	ldrb r4, [r6], $1
	b _parse



_binary:
 	b _bin_asciibin

_integer:
	mov r3, $'-'
	teq r0, $(1<<31)			@ xor allows beq to work later
	rsbpl r0, r0, $0			@ get 2's compliment if n = 1
	strplb r3, [r5], $1			@  (note teq 1<<31 will reverse
						@	n flag, think about it)
	subpls r7, r7, $1 
	beq _str_end
	b _bin_asciidec

_unsignedd:
	b _bin_asciidec


_string:
	rsb r7, r7, $0				@ 2's compl to tst against the n
						@  flag. save on an extra cmp
	ldrb r1, [r0], $1
_S0:
	teq r1, $0				@ tst if 0 without setting c flag
	strneb r1, [r5], $1
	addnes r7, r7, $1			@ all time n flag set its ok
	ldrneb r1, [r0], $1
	bne _S0					@ if r1 | r7 != 0 then b to _S0
	rsbcc r7, r7, $0			@ convert back from 2's compl
	ldrccb r4, [r6], $1			@ if c =1 then r7 added up to 0
	bcc _parse
	b _str_end



_char:
	subs r7, r7, $1
	beq _str_end
	ldrb r4, [r6], $1
	strb r0, [r5], $1
	b _parse

_float:	@ doubtfull it would be of any use but usefull excercise to impliment
_hex:
	b _bin_asciihex

_ins_var:
	sub r2, r0, r1				@ get number of chars to print
	subs r3, r8, r2				@ fsp_width v actual number width
	subhi r7, r7, r3
	subs r7, r7, r2
	ble _str_end

	subs r3, r3, $1
_inv0:
	strgeb r9, [r5], $1
	subs r3, r3, $1
	bge _inv0

	ldrb r4, [r0, #-1]!

_inv1:
	strb r4, [r5], $1
	subs r2, r2, $1
	ldrneb r4, [r0, #-1]!
	bne _inv1
	ldrb r4, [r6], $1
	b _parse

_str_end:
	mov r4, $0
	strb r4, [r5] 			@ ensure there is a NULL
	cmp r7, $0			@ reason why here? (space or null byte)
	
	movgt r0, $0
	mvnle r0, $0
	rsbgt r2, r7, $1024
	ldrle r2, =BOLength
	ldrgt r1, =StdOut
	ldrle r1, =BufferOverflow
/*EXIT*/
	ldmfd sp!, {r4 - r10, lr}		@ return
	add sp, sp, $0xc			@ adjust sp back 12bytes
	bx lr

	
_bin_asciihex:
	/* binary to hex in assci converter. Converts value in r0 to hex
	 * Returns ascii coded value in memory location AsciiDigit.
	 * R0 holds pointer to first char to be printed. r1 holds base
	 * address which will also be the last char. note data is stored
	 * in a decrement array ***  make sure to DECREMENT the address ***
	* from any higher value (for this very basic os!) */
	ldr r12, =BinHexTable			@ load table with ascii char set
	ldr r3, =AsciiDigit			@ AsciiDigit array holding char
	and r1, r0, $0xf
	ldrb r2, [r12, r1]
_BH0:
	strb r2, [r3], $1
	movs r0, r0, lsr $4
	andne r1, r0, $0xf
	ldrneb r2, [r12, r1]
	bne _BH0
	
	mov r0, r3
	ldr r1, =AsciiDigit
	bx lr

_bin_asciibin:
	/* _bin_asciibin converts 1 word (4bytes) value into an ascii string
	 * of a binary number. The value to be converted is passed via r0.
	 * The return string being potentially too long to return in r0-r3 is
	 * instead passed via a pointer to a mem location (AsciiBin). R0 holds
	 * the pointer to 1st char to be poped (1st char at hi address last char at
	 * lo address) r1 the base address. (r0 - r1 = n.o char) */
	ldr r12, =AsciiDigit
	mov r2, $0x30				@ ascii '0'
	mov r3, $0x31				@ ascii '1'
	movs r0, r0, lsr $1
_BA:
	strccb r2, [r12], #1
	strcsb r3, [r12], #1
	movs r0, r0, lsr $1
	bne _BA
	mov r0, r12
	ldr r1, =AsciiDigit
	bx lr

_bin_asciidec:
	/* Convert binary number (=< 32bits) into ascii decimal values */
	/* Toyed with idea of using double dabble method to get binary numbers
	 * stored in bcd format and then adding 0x30h to get ascii code for
	 * each 4bit bcd, but as much as i love the algorithm its way to slow
	 * for 32 bits so instead its div by 10, convert remainder to ascii
	 * store and repeat by div quotant and convert remainder.
	 * routine returns r0 pointer to 1st B to pop, r1 pointer to last B
	*/
	ldr r1, =0xcccccccd			@ 1/10 << 35
	ldr r12, =AsciiDigit 
_DA:
	umull r2, r3, r0, r1
	mov r0, r3, lsr $3			@ move quotent back into r0
	and r3, r3, $7				@ isolate remainder 
	add r3, r3, lsl $2			@ r = r *5 << 3
	movs r3, r3, lsr $2			@ r = r*2 >>3
	movccs r2, r2, lsl $1			@ test if rounding correction needed 
	addcs r3, r3, $1				@ the remainder
	/* 'convert into ascii and store */
	add r3, r3, $0x30
	strb r3, [r12], $1
	cmp r0, $10
	bpl _DA
	add r0, r0, $0x30
	strb r0, [r12], $1			@ still inc to have char n.o correct
	mov r0, r12				@ r0; 1st char to pop here
	ldr r1, =AsciiDigit			@ r1; last char to pop here
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
	ldr r12, =AsciiDigit
	cmp r1, $0				@ see if can skip to 32bit mul
	beq _DL0
	sub hi10, lo10, $0x1
_DLA:
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

	/* 'convert into ascii and store */
	add scratch, scratch, $0x30
	strb scratch, [r12], $1

	/* 'straighten' out hlo hhi (quotent) by >> 3 and putting them in r0:r1*/ 
	mov r0, hlo, lsr $3
	ands scratch, hhi, $7
	orrne r0, r0, scratch, ror $3
	movs r1, hhi, lsr $3
	bne _DLA
_DL0:
	mov r1, lo10
	ldmfd sp!, {r4 -r8}			@ Normally I would have this just 
						@  before returning from routine
						@  but as this is soo time consuming
						@  having this instruction here
						@  shaves a few cpu cycles!!
_DL1:
	umull r2, r3, r0, r1
	mov r0, r3, lsr $3			@ move quotent back into r0
	and r3, r3, $7				@ isolate remainder 
	add r3, r3, lsl $2			@ r = r *5 << 3
	movs r3, r3, lsr $2			@ r = r*2 >>3
	movccs r2, r2, lsl $1			@ test if rounding correction needed 
	adc r3, r3, $0				@ the remainder

	add r3, r3, $0x30
	strb r3, [r12], $1
	cmp r0, $10
	bpl _DL1
	add r0, r1, $0x30
	cmp r0, $10
	bpl _DL1
	add r0, r1, $0x30
	strb r0, [r12]
	mov r0, r12				@ pointer to 1st char to pop
	ldr r1, =AsciiDigit			@ pointer off last char to pop
	bx lr

	.unreq lo10
	.unreq hi10
	.unreq llo
	.unreq lhi
	.unreq hlo
	.unreq hhi
	.unreq scratch

        /* Format specifiers -- to be moved */
_h5x:
        .ascii "%x"
_h5d:
	.ascii "%d"
_h5c:
	.ascii "%c"
_h5s:
	.ascii "%s"

	.DATA
	.align 2
BinHexTable:
	.byte '0'
	.byte '1'
	.byte '2'
	.byte '3'
	.byte '4'
	.byte '5'
	.byte '6'
	.byte '7'
	.byte '8'
	.byte '9'
	.byte 'A'
	.byte 'B'
	.byte 'C'
	.byte 'D'
	.byte 'E'
	.byte 'F'

AsciiDigit:
	.rept 0x20
	.byte 0
	.endr

BufferOverflow:
	.asciz "Max string length reached"
BOLength= .-BufferOverflow
	  


