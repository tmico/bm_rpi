	/* rewriting _write_tbf function */

	.global _tty_console_in
	.align 2

	.text

TtyLock:
	.word 0
_tty_console_in: 				@-- change to better named label!
	/* Takes a string (r0 = string addr) and puts it in ConsoleFifo queue
	   INPUT  r0 = string addr 
		  r1 = size (inc null char)
	*/
	ldr r3, =TtyLock			@ Need a lock to prevent
	mov r12, $1				@ ...a 0x2000 char string
	ldrex r2, [r3]				@ ...from being split apart
	cmp r2, $0
	strexeq r2, r12, [r3]
	cmp r2, $0
	bne _tty_console_in
	
	stmfd sp!, {r4 - r7, lr}
	mov r4, r0
	mov r6, r1				@ preserve
_get_free_buffer:	
	ldr r0, =FreeBufList
	bl _fdequeue
	cmp r0, $0				@ zero in this case is failed...
	beq _get_free_buffer			@ ...to get a free buffer 
	mov r7, r0				@ preserv addr

	/* Use strcpy to copy string to given Out buffer. If string longer
	   than Max then request next free buffer(s) to copy remainder of
	   string to
	*/
	mov r2, $0x2000
	sub r2, r2, $1				@ sub 1 to allow null byte
	subs r5, r5, r2
	addmi r2, r2, r5
	add r6, r2, $1
	mov r1, r4
	addpl r4, r4, r2 
	bl _strcpy				@ transfer string to buffer

	mov r1, $0				@ add a null pointer ...
	strb r1, [r0, r6] 			@ ...to be safe

_put_in_ConsoleFifo:	
	ldr r0, =ConsoleFifo
	mov r1, r7
	bl _fenqueue
	cmp r0, $0
	bne _put_in_ConsoleFifo
	

	cmp r5, $0				@ string completly copied?
	bgt _get_free_buffer

	ldr r2, =TtyLock
	mov r3, $0
	str r3, [r2]
	mcr p15, 0, r3, c7, c10, 5		@ DMB
	ldmfd sp!, {r4 - r7, pc}

@===============================================================================

_tty_console_out:	
	/* Fetches from ConsoleFifo the next string to be printed to
		the console.
	   pass address to _tty_write to put string in consoles buffer
	   _tty_display displays to console the contents of consoles buffer
	*/
	stmfd sp!, {lr}
_tco:	
	ldr r0, =ConsoleFifo
	bl _fdequeue
	cmp r0, $0				@ have we got an address?
	bne _tco

	ldr r1, =TermInfo
	bl _tty_write

	cmp r0, $0

	ldr r0, =TermInfo
	bleq _tty_display
	ldmfd sp!, {pc}

@===============================================================================

_tty_write:
	/* _tty_write converts string buffer given to it via r0 as a byte
	   per char into 2bytes per char by inserting in the high bits 
	   (15:8) 16 colour code for background (high nibble) and font (low
	   nibble) 
	   Input: R0 &StdOut
		  R1 &TermInfo
	*/
	stmfd sp!, {r4,r5,r6,r10,r11}
	ldr r5, [r1, $8]			@ get address of TermCur...
	ldr r4, [r1, $28]			@ get n.o char per line to use
	ldr r11, [r1]				@ get Termbuffer address
	ldr r12, [r1, $16]			@ get TermColour
	mov r10, r0				@ free up r{0,1,2,3}
	mov r6, r1
	cmp r4, $127				@ max 128 char per line
	movhi r4, $79				@ if > assume error
	strhi r4, [r1, $28]			@ save corrected number
	mov r12, r12, lsl $8			@ hi byte format, lo byte char

	/* find out how many spaces left on line. If cusor position exceeds
	   max number of chars per line then incerment line number and reset
	   position to 2st char on line
	*/
	and r0, r5, $0xfe			@ isolate cursor position
	cmp r4, r0, lsr $1			@ is cursor beyond column limit?
	subhi r4, r4, r0, lsr $1		@ if not calculate space left
	addls r5, r5, $(1<<8)			@ if true inc line number (bit 8)
	andls r5, r5, $(0x7f<<8)		@  and reset cursor (bits 7:0)

	/* Output string into TermBuffer. Routine is ldr char, branch if special
	   str byte if not and increment cusor position or line number if
	   end of line reached 
	*/
	ldrb r0, [r10]
_wtb0:
	cmp r0, $0x20				@ Special char?
	bmi _spchar

	orr r0, r0, r12				@ add term color
	strh r0, [r11, r5]
	add r5, r5, $2
	subs r4, r4, $1				@ decr char per line
	ldrb r0, [r10, $1]!
	bne _wtb0

	/* if Max number of char reached then wrap round to next line*/
	mov r2, $'\n'
	strh r2, [r11, r5]
	add r5, r5, $(0x1<<8)			@ if end of line inc to nxt
	and r5, r5, $(0x7f<<8)			@  line and reset cursor
	ldr r4, [r6, $28]			@ get max char per line
	b _wtb0

	/* Testing the following block of code, poss cause an abort?
	   if char is a special ie, \n, \r, etc ... then use a branch table to
	   branch to correct 'handle'.
	*/
_spchar:
		@ experimental way to try it??
	ldr pc, [pc, r0, lsl $2]
	.word _NotImp				@ here to make line above work
CharTable:
	.word _Null		@Null
	.word _NotImp		@SOH
	.word _NotImp		@STX
	.word _NotImp		@ETX
	.word _NotImp		@EOT
	.word _NotImp		@ENQ
	.word _NotImp		@ACK
	.word _NotImp		@BEL
	.word _BackSpace	@BS 0x8
	.word _NotImp		@HT
	.word _LineFeed		@LF 0xa
	.word _NotImp		@VT
	.word _NotImp		@FF
	.word _CarriageReturn	@CR 0xd
	.word _NotImp		@SO
	.word _NotImp		@SI
	.word _NotImp		@DLE
	.word _NotImp		@DC1
	.word _NotImp		@DC2
	.word _NotImp		@DC3
	.word _NotImp		@DC4
	.word _NotImp		@NAK
	.word _NotImp		@SYN
	.word _NotImp		@ETB
	.word _NotImp		@CAN
	.word _NotImp		@EM
	.word _NotImp		@ESC 0x1b
	.word _NotImp		@FS
	.word _NotImp		@GS
	.word _NotImp		@RS
	.word _NotImp		@US

	/* _NotImp : Not Implimented. a safe return to _wtb0 */
_NotImp:

	ldrb r0, [r10, $1]!			@ get next char
	b _wtb0

	/* End of string value is 0x0. str and exit */
_Null:
	mov r0, $0
	strh r0, [r11, r5]
	ldr r1, =TermInfo			@ save new location of Termbuffer
	str r5, [r1, $8]			@ get address of TermCur (current line)
	ldmfd sp!, {r4, r5, r6, r10, r11}
	bx lr

	/* \n char; create new line, reset cursor and ldr char per line */
_LineFeed:
	orr r0, r0, r12
	strh r0, [r11, r5]
	add r5, r5, $(0x1<<8)
	and r5, r5, $(0x7f<<8)
	/* zero out line to rid old char's */
	mov r0, $0
	mov r1, $0
	mov r2, $0x20				@ 256 bytes / 8 = 0x20 (32)
	add r3, r11, r5				@ r3 = addr of new line
_lf0:
	strd r0, r1, [r3], $8
	subs r2, r2, $1				@ loop to zero out line
	bne _lf0

	ldr r4, [r6, $28]			@ get max char per line
	ldrb r0, [r10, $1]!			@ get next char
	b _wtb0

	/* Backpace. Go back 1 place and (over)write char with \b, (1) test
	 * to see if beginning of line is reached and thus need to go up
	 * one line. (2) walk through line to locate \n marker to get last char
	 * to delete (3) str \b inplace of last char
	*/
_BackSpace:
	ldr r2, [r6, $28]			@ get n.o char per line
	add r4, r4, $1
	orr r1, r1, r12				@ add term colour
	cmp r4, r2				@ do we need to go up a line?

	subls r5, r5, $2			@ go back 1 place
	strlsh r1, [r11, r5]			@ if same line str 'block'
	ldrb r0, [r10, $1]!			@ get next char ready
	bls _wtb0

	sub r5, r5, $(1<<8)			@ adjust and find \n point on
	and r5, r5, $(0x7f<<8)			@  line above

	ldrb r3, [r11, r5]			@ walk thru till find \n
_bs2:	cmp r3, $0xa
	addne r5, r5, $2
	ldrneb r3, [r11, r5]
	bne _bs2
	strh r1, [r11, r5]
	and r4, r5, $0xfe			@ calculate char spaces left
	mov r4, r4, lsr $1
	sub r4, r2, r4

	b _wtb0

_CarriageReturn:
	ldrb r0, [r10, $1]!
	ldr r4, [r6, $28]			@ reset char per line
	bic r5, r5, $0xff
	b _wtb0


	/* _tty_display will read from TermBuffer + TermCur (the offset to 
		start reading from) and out put contents to screen and or uart
	  input: r0 = TermInfo
	  output r0 = 0 success | -1 fail
	  Description: 
	*/
_tty_display:
	stmfd sp!, {r4 - r11, lr}
	/* Find out which line number is last line of text. If == $(MaxNuLines)
	   then a complete rewrite of the screen (scrolling) needs to happen
	   the last line displayed on screen remains blank after a '\n'
	*/
	ldr r4, [r0, $24]			@ fetch max n.o lines
	ldr r5, [r0, $20]			@ fetch CurLine (screen line)
	ldr r6, [r0, $40]			@ fetch DTermCur (last saved loc)
	ldr r7, [r0]				@ fetch address of TermBuffer
	ldr r8, [r0, $32]			@ fetch x (cursor position)
	ldr r9, [r0, $36]			@ fetch y (line number)
	mov r11, r0				@ preserve

_display_string:
	cmp r4, r5				@ reached bottom of screen?
	blls _scroll_screen			

	add r0, r9, $16
	bl _clear_line				@ clear line bellow

_display_char:
	ldrh  r10, [r7, r6]                     @ ldr the char and colors
	mov r2, r8				@ copy x
	mov r3, r9				@ copy y
	and r0, r10, $0xff			@ put char in r10
	cmp r0, $0x20				@ is it special
	blo _special_char
	and r1, r10, $0xff00			
	mov r1, r1, lsr $8			@ r1 = bg;fg

	bl _draw_char
	add r6, r6, $2
	bic r6, r6, $(80<<8)			@ looping buffer; stop overflow
	add r8, r8, $1				@ mov x to next place on line
	b _display_char

	/* lookup table to branch to correct special char handler.
	   There is an extra unused line after ldr pc instruction to
	   position jump table 3 instruction on from pc
	*/
_special_char:
	ldr pc, [pc, r0, lsl $2]
	.word _null
CharTableDisplay:
	.word _null		@Null
	.word _noti		@SOH
	.word _noti		@STX
	.word _noti		@ETX
	.word _noti		@EOT
	.word _noti		@ENQ
	.word _noti		@ACK
	.word _noti		@BEL
	.word _back_space	@BS 0x8 '/b'
	.word _noti		@HT
	.word _n_line		@LF 0xa	'/n'
	.word _noti		@VT
	.word _noti		@FF
	.word _carriage_return	@CR 0xd
	.word _noti		@SO
	.word _noti		@SI
	.word _noti		@DLE
	.word _noti		@DC1
	.word _noti		@DC2
	.word _noti		@DC3
	.word _noti		@DC4
	.word _noti		@NAK
	.word _noti		@SYN
	.word _noti		@ETB
	.word _noti		@CAN
	.word _noti		@EM
	.word _noti		@ESC 0x1b
	.word _noti		@FS
	.word _noti		@GS
	.word _noti		@RS
	.word _noti		@US
_null:	       
	str r5, [r11, $20]			@ save CurLine (screen line)
	str r6, [r11, $40]			@ save DTermCur
	str r8, [r11, $32]			@ save x (cursor position)
	str r9, [r11, $36]			@ save y (line number)

	ldmfd sp!, {r4 - r11, pc}

_noti:
	nop
_back_space:
	/* replace '\b' with a '\0', move one place back and print a space char
	 */
	mov r0, $0
	strh  r0, [r7, r6]                     	@ zero out '\b'
	ldr r1, [r11, $16]			@ ldr color
	mov r2, r8
	mov r3, r9
	mov r0, $0x20				@ put a space instead
	bl _draw_char
	subs r8, r8, $1			       	@ mov x back 1 and tst not -1
	subpl r6, r6, $2			@ Go back 1 char in TerBuffer
	bpl _display_char
_upl:	
	ldr r3, [r11, $48]			@ Get max char per line 
	subs r5, r5, $1
	movmi r5, $0				@ if top of screen stay there
	subpl r9, r9, $1
	movmi r9, $0
	sub r6, r6, $(1<<8)			@ go back one line in buffer
	and r6, r6, $(0x7f<<8)
	add r6, r6, r3, lsl $1			@ add end char loc
	ldrb r0, [r7, r6]			@ ldr and tst till last char
_upl1:	
	cmp r0, $0
	subeq r6, r6, $2
	ldreqb r0, [r7, r6]			@ ldr and tst till last char
	beq _upl1
	and r3, r6, $0x7f			@ isolate line position
	mov r8, r3, lsr $1			@ get x from r3
	b _display_char
	
_n_line:
	mov r8, $0				@ reset x to begining of line
	add r9, r9, $1				@ y = new line bellow
	add r5, r5, $1				@ CurLine = next line
	add r6, r6, $(0x1<<8)			@ adjust DTermCur to point
	and r6, r6, $(0x7f<<8)			@  to new line in TermBuffer
	b _display_string

_carriage_return:	
	mov r8, $0
	and r6, r6, $(0x7f<<8)			@  Back to start of line
	b _display_char

_scroll_screen:
	/* Re-set TermStart to pojnt to next line. reset TermCur to point to same address
	   clear line using a dma transfer (color set to bg color of 1st char)
	   note in TermBubber bits 0:7 used for col 8:14 used for line. (total 127 lines)
	*/
	ldr r1, [r11, $4]			@ ldr TermStart
	mov r5, $0x0				@ go back to top of screen
	mov r8, $0x0
	mov r9, $0x0				@ reset cursur back to top left
	add r1, r1, $0x100			@ move forward 1 line
	and r1, r1, $0x7f			@ cyclic buffer so mask
	str r1, [r11, $4]
	mov r6, r1				@ DTermCur = TermStart

	/* Clear top line of screen */
	stmfd sp!, {lr}
	bl _clear_line
	ldmfd sp!, {pc}

_clear_line: 
	/* Clear first line of the screen using dma. The control block is
	   preset with defaults for a 80 char with 8x16 fonts screen. 
	   r2,r3,r12 free as scratch registers 
	   r9 = y, r1 =GraphicsAdr
	*/

	ldr r1, =GraphicsAdr

	/* The DEST_AD in the control block is:
		pixels/width * bytes/pixel * no of lines/glyph * y + GraphicsAdr
		1280 * 4 * 16 * y + GraphicsAdr  if defaults values are used
	*/
	mov r2, $1280
	ldr r3, [r1]				@ get GraphicsAdr
	mov r2, r2, lsl $6			@ *64 (*4*16)
	ldr r0, =CB_ClearLine
	mla r1, r9, r2, r3			@ * y + GraphicsAdr
	stmfd sp!, {lr}
	str r1, [r0, $4]
	bl _clrl_dma0				@ dma will do the rest
	ldmfd sp!, {pc}				@ return


	/*r0-r3 = scratch, r10 = char, r8 = x, r9 = y */  
	.data
	.align 2

	.global TermInfo
TermInfo:				@ Data array 
	.word TermBuffer	@ #0 pointer to termbuffer
	.word TermBuffer	@ #4 TermStart set to termbuffer at start
	.word 0x00		@ #8 TermCur (bits 14:8 - Line No, 7:0 - cursor
	.word 0x00		@ #12 LastColour (Use to cmp against)
	.word 0x2		@ #16 TermColour (bg,hi nibble:fg,lo nibble)
	.word 0x00		@ #20 Current Screen Line (CurLine)
	.word 0x2c		@ #24 Max Number of Lines default:45 [0-44;0-2c]
	.word 0x49		@ #28 Max number of char/line (LineLength:80)
	.word 0x0		@ #32 Cursloc x
	.word 0x0		@ #36 Cursloc y
	.word 0x0		@ #40 DTermCur for tty_display

	.global BlankLine
BlankLine:			@ Empty blank line to clear 8 pixiles in a row
	.rept 16		@ 128 bit
	.byte 0x0		@ black
	.endr

FreeBufList:
	.word 0 			@ lock
	.word FreeBufList + 16		@ Head
	.word FreeBufList + 44		@ Tail
	.word 32			@ Size (bytes)
	.word Out0
	.word Out1
	.word Out2
	.word Out3
	.word Out4
	.word Out5
	.word Out6
	.word Out7
Out0:
	.rept 0x2000
	.byte 0x0		@ Buffer 0
	.endr
Out1:
	.rept 0x2000
	.byte 0x0		@ Buffer 1
	.endr
Out2:
	.rept 0x2000
	.byte 0x0		@ Buffer 2
	.endr
Out3:
	.rept 0x2000
	.byte 0x0		@ Buffer 3
	.endr
Out4:
	.rept 0x2000
	.byte 0x0		@ Buffer 4
	.endr
Out5:
	.rept 0x2000
	.byte 0x0		@ Buffer 5
	.endr
Out6:
	.rept 0x2000
	.byte 0x0		@ Buffer 6
	.endr
Out7:
	.rept 0x2000
	.byte 0x0		@ Buffer 7
	.endr

ConsoleFifo:			@ A fifo holding start addresses of strings
	.word 0			@ lock
	.word 0			@ head
	.word 0			@ tail
	.word 32		@ size in bytes
	.rept 8		
	.word 0			@ fifo buffer
	.endr

	.align 8
TermBuffer:
	.rept 128 * 128
	.hword 0x11
	.endr
