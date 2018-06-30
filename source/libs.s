	.text
	.align 2
	.global _kprint

/*---------------------------------------------------
 * _kprint: A mini printf function
 *	Input:	r0 string address
 *		r1 - r3 interger, character (ascii), address of string (pointer)
 *		stack additional args (int, char, string address)
 *	Output: r0 &string
 --------------------------------------------------*/

		/*%c	single char*/
		/*%d	decimal int*/
		/*%b	binary int*/
		/*%f	float  ---> not yet implemented*/
		/*%s	string*/
		/*%x	hexadecimal*/
		/*%u	unsigned*/
		/*%l	long (64 bit)*/

_kprint:	
	stmfd sp!, {r3}				@ str args for easy access
	stmfd sp!, {r2}				@ str args for easy access
	stmfd sp!, {r1}				@ str args for easy access
	mov r12, sp
	sub sp, sp, $1024			@ create room on stack
	stmfd sp!, {r4 - r10, lr}
	ldrb r4, [r0], $1			@ r5 = points to 1st space
	add r5, sp, $32				@  on stack
	mov r6, r0				@ copy addr of string input
	mov r7, $1024				@ max char length counter
	mov r10, r12

_parse:
	teq r4, $'%'				@ '%' a la printf()
	beq _forsp				@ FORmatSPecifier
	teq r4, $0				@ NULL terminator
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
	cmp r4, $0x39				@ is '%' followed by a number?
	bic r3, r4, $0xe0			@ clear to 'switch' case of char
	bls _forsp
	mov r1, r3, lsl $2			@ * 4 to word align
	add r1, r1, r0
	ldr r2, [r1]				@ branch to correct %d,b,x
	ldmfd r10!, {r0}
	ldr lr, =_ins_var
	bx r2

	/* Calculate width to print with or without leading zero's 
	   r4 - ascii number, r8 - width, r9 - leading char (' ' or '0') */
	subs r2, r4, $0x30			@ block decides on space or 0
	bmi _for1				@ if not number b to 
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
	.word	_bin_asciidec_long @l
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
	/* r7 = remaining space on stack, r8 = width, r9 = leading char, eg 002 */
_ins_var:
	subs r3, r8, r1				@ fsp_width v actual number width
	subhi r7, r7, r3
	subs r7, r7, r1
	ble _str_end

	subs r3, r3, $1
_inv0:
	strgeb r9, [r5], $1
	subs r3, r3, $1
	bge _inv0

	ldrb r4, [r0], $1

_inv1:
	strb r4, [r5], $1
	subs r1, r1, $1
	ldrneb r4,[r0], $1
	bne _inv1

	ldrb r4, [r6], $1			@ return to next char in string
	b _parse

_str_end:
	mov r4, $0
	strb r4, [r5]				@ ensure there is a NULL
	cmp r7, $0				@ reason why here? (space or null byte)
	
	movgt r0, $0
	mvnle r0, $0
	rsbgt r1, r7, $1024
	ldrle r1, =BOLength
@--	rsbgt r2, r7, $1024
@--	ldrle r2, =BOLength
/*EXIT*/
@--	movgt r1, sp
@--	ldrle r1, =BufferOverflow
	add r0, sp, $32
	bl _puts				@ puts calls syscall write
	ldmfd sp!, {r4 - r10, lr}		@ return
	add sp, sp, $1024
	add sp, sp, $0xc			@ adjust sp back 1036bytes
	bx lr
	
_bin_asciihex:
	/* binary to hex in assci converter. Converts value in r0 to hex
	 * Returns ascii coded value in memory location AsciiDigit.
	 * R0 holds pointer to first char to be printed. r1 holds base
	 * address which will also be the last char. note data is stored
	 * in a decrement array ***  make sure to DECREMENT the address ***
	* from any higher value (for this very basic os!) */
	ldr r12, =BinHexTable			@ load table with ascii char set
	mov r3, sp
	and r1, r0, $0xf
	ldrb r2, [r12, r1]
_BH0:
	strb r2, [r3, $-1]!
	movs r0, r0, lsr $4
	andne r1, r0, $0xf
	ldrneb r2, [r12, r1]
	bne _BH0
	
	mov r0, r3
	sub r1, sp, r3				@ n.o chars
	bx lr

_bin_asciibin:
	/* _bin_asciibin converts 1 word (4bytes) value into an ascii string
	 * of a binary number. The value to be converted is passed via r0.
	 * The return string being potentially too long to return in r0-r3 is
	 * instead pushed onto the stack. R0 holds
	 * the pointer to 1st char to be poped (1st char at lo address last char at
	 * hi address) r1 the base address. (r0 - r1 = n.o char) */
	mov r12, sp				@ copy
	mov r2, $0x30				@ ascii '0'
	mov r3, $0x31				@ ascii '1'
_BA:
	movs r0, r0, lsr $1
	strccb r2, [r12, #-1]!
	strcsb r3, [r12, #-1]!
	bne _BA
	mov r0, r12				@ addr of 1st char
	sub r1, sp, r12				@ n.o char
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
	mov r12, sp				@ copy 
_DA:
	umull r2, r3, r0, r1
	mov r0, r3, lsr $3			@ move quotent back into r0
	and r3, r3, $7				@ isolate remainder 
	add r3, r3, lsl $2			@ r = r *5 << 3
	movs r3, r3, lsr $2			@ r = r*2 >>3
	movccs r2, r2, lsl $1			@ is rounding correction needed 
	adc r3, r3, $0x30			@ add carry and 'make' it ascii

	strb r3, [r12, $-1]!			@ full dessending so pre increment
	cmp r0, $10
	bpl _DA
	add r0, r0, $0x30
	strb r0, [r12, $-1]! 
	mov r0, r12				@ r0; pointer to 1st char
	sub r1, sp, r12				@ n.o of char
	bx lr

_bin_asciidec_long:
	/* Convert a 64 bit binary number into ascii decimal values
	   This routine make use of the 'multiply long accumalate' op in the
	   arm11 unit. Neadless to say this is a time consumiing operation
	   r0 is lo; r1 is hi
	*/
	/* r2,r3 hold reciprical of 10 (1/10) << 3 */
	/* r4:r5 low; r6:r7 high of result which is put back into r0:r1 */
	ldr r2, =0xcccccccd			@ hi reciprical
	ldr r3, =0xcccccccc			@ lo reciprical
	mov r12, sp
	ldmfd r10!, {r1}
	sub sp, sp, $24				@ create room
	stmfd sp!, {r4 - r7}

_1:
	umull r4, r5, r0, r2			@ low * low
	mov r6, $0
	umlal r5, r6, r1, r2			@ low * high
	mov r7, $0
	umlal r5, r7, r0, r3			@ high * low
	mov r4, $0
	adds r6, r6, r7				@ carry set unpredictable
	adc r7, r4, $0				@  so this workaround
	umlal r6, r7, r1, r3			@ high * high

	/* seperate remainder and mull by 10 */
	and r4, r6, $7
	add r4, r4, r4, lsl $2
	movs r4, r4, lsr $2
	movccs r5, r5, lsl $1
	adc r4, r4, $0x30			@ correct rounding error
						@  and 'make' it ascii
	strb r4, [r12, $-1]!

	/* put r6:r7 in r0:r1 stripping remainder from r6 */
	mov r0, r6, lsr $3			@ adjust having r2:r3 << 3
	and r5, r7, $7				@ mov r7,0:3 to r6,28:31
	orr r0, r0, r5, ror $3
	movs r1, r7, lsr $3
	bne _1					@ if zero _DLb is faster
	mov r1, r2

_DLb:
	umull r2, r3, r0, r1
	mov r0, r3, lsr $3			@ move quotent back into r0
	and r3, r3, $7				@ isolate remainder 
	add r3, r3, lsl $2			@ r = r *5 << 3
	movs r3, r3, lsr $2			@ r = r*2 >>3
	movccs r2, r2, lsl $1			@ test if rounding correction needed 
	adc r3, r3, $0x30			@ the remainder

	strb r3, [r12, $-1]!
	cmp r0, $10
	bpl _DLb
	add r0, r0, $0x30

	strb r3, [r12, $-1]!
	cmp r0, $10
	bpl _DLb
	add r0, r0, $0x30
	strb r0, [r12, $-1]!
	ldmfd sp!, {r4 -r7}
	mov r0, r12				@ pointer to 1st char to pop
	add sp, sp, $24				@ correct sp
	sub r1, sp, r12				@ n.o char
	bx lr
        /* Format specifiers -- to be moved */
_h5x:
        .ascii "%x"
_h5d:
	.ascii "%d"
_h5c:
	.ascii "%c"
_h5s:
	.ascii "%s"

	.data
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


BufferOverflow:
	.asciz "Max string length reached"
BOLength= .-BufferOverflow
	  
	.text
	.align 2
	.global _puts
/*------------------------------------------------
 * puts: prints a string to stdout
 *	input; r0 = &string
 -----------------------------------------------*/
_puts:
	stmfd sp!, {r7, lr}
	mov r2, r1
	mov r1, r0
	mov r0, $1
	mov r7, $4
	svc 0
	ldmfd sp!, {r7, pc}


	.global _strcpy
_strcpy:	
	/* Copy at most n (r2) charactors from source (r1) to destination (r0)
	   The may or may not be null terminated
	   Returns: r0 = Destination addr
		    r1 = last byte to be copied
	*/
	ldrb r3, [r1]
	mov r12, r0
	subs r2, r2, $1
	beq _exit0
_stcp:	
	strb r3, [r0], $1
	subs r2, r2, $1
	ldrb r3, [r1, $1]!
	bhi _stcp
	b _exit0

	.global strncpy
_strncpy:
	/* Copy at most n (r2) charactors from source (r1) to destination (r0)
	   Pad with '\0' if source has less than n charactors
	   The may or may not be null terminated
	   Returns: r0 = Destination addr
		    r1 = last byte to be copied
	*/
	ldrb r3, [r1]
	mov r12, r0
	subs r2, r2, $1
	beq _exit0
_stncp:	
	cmp r3, $0
	beq _pad
	strb r3, [r0], $1
	subs r2, r2, $1
	ldrb r3, [r1, $1]!
	bhi _stncp

_exit0:
	strb r3, [r0]
	mov r1, r3				@ return last byte of string
	mov r0, r12				@ and dest addr
	bx lr	
_pad:
	mov r3, $0
_p1:
	strb r3, [r0], $1
	subs r2, r2, $1
	ldrb r3, [r1, $1]!
	bhi _p1
	b _exit0

