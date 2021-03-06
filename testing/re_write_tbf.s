	/* rewriting _write_tbf function */

	.global _tty_console
	.global _start
	.global main
	.align 2

	.text
main:
_start:		@ here for gdb puposes
	nop
	ldr r1, =HelloWorld
	ldr r0, =StdOut
_st:	ldrb r2, [r1], $1
	strb r2, [r0], $1
	cmp r2, $0
	bne _st
	ldr r0, =StdOut

	@ don't forget to delete||||
	@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	/* _tty_console : Sends StdOut to _tty_write to be put on the
	   the TermBuffer. _tty_write returns to _tty_console a $0 or $-1.
	   0 = success, -1 = failed. 
		if 0 then branch to _display_tty to refresh terminal display
		if -1 then bx lr with error
	   _tty_write : writes char's within string to TermBuffer
	   r0 input string (StdOut)
	   r1 address of TermInfo data array
	   Returns:
	   r0 output , 0 success, -1 error
		TermBuffer0 is aligned 8 
	*/
	/* _tty_write converts string buffer given to it via r0 as a byte
	   per char into 2bytes per char by inserting in the high bits 
	   (15:8) 16 colour code for background (high nibble) and font (low
	   nibble) 
	/* Charactor editing (such as deleting) for the console only 
	   works for the current string. Pressing the backspace key for
	   will only delete char found in kb_input buffer. Obviously
	   a user typing will want to see the keys pressed echo'd back
	   on screen and as such the kb_buffer has to be kept 'open' even
	   as display_tty function updates the screen. The kb_buffer
	   is reset when the return\enter is pressed. Responsibility
	   then is passed to whichever function is putting char's in the
	   buffer. The buffer is reset when Base address is started from
	*/
	/* REMINDERS: TermColour needs to be called by _display_tty */
_tty_console:
	/* r0 holds current char (byte) address 
	   
	   Before loading reg and branching to _tty_write test pointer holds
	   a valid null terminator and does not excede 4096 bytes
	*/
	@ Delete nop
	nop		@ here to help gdb
	ldr r1, =StdOut
	mov r3, r0				@ preserve string addr

	ldrb r2, [r3], $1
_chk_size:
	cmp r2, $0
	ldrneb r2, [r3],$1
	bne _chk_size

	sub r2, r3, r1				@ chk r0 !> (StdOut+4096)
	cmp r2, $0x1000				@ treat neg num as large %d
	mvnhi r0, $0				@ if buffer to big return -1
	bxhi lr
	
	push {lr}
	ldr r1, =TermInfo

	bl _tty_write

	cmp r0, $0

	/* if error (not zero) then print error message if possible */
	@ bne _tty_error
	/* if no problems b to _tty_display (display to monitor or uart */
	ldr r0, =TermInfo
	bleq _tty_display

_tty_write:
	/* Input: R0 &StdOut
		  R1 &TermInfo
	*/
	stmfd sp!, {r4,r5,r6,r10,r11}
	ldr r5, [r1, $8]			@ get address of TermCur (current line)
	ldr r4, [r1, $28]			@ get n.o char per line to use
	ldr r11, [r1]				@ get Termbuffer address
	ldr r12, [r1, $16]			@ get TermColour
	mov r10, r0				@ free up r{0,1,2,3}
	mov r7, r1
	cmp r5, $127				@ max 128 char per line
	movhi r5, $127
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

	subs r4, r4, $1				@ decr char per line
	orr r0, r0, r12				@ add term color
	strneh r0, [r11, r5]
	addne r5, r5, $2
	ldrb r0, [r10, $1]!
	bne _wtb0

	/* if Max number of char reached then wrap round to next line*/
	mov r2, $'\n'
	strh r2, [r11, r5]
	add r6, r5, $(0x1<<8)			@ if end of line inc to nxt
	and r6, r5, $(0x7f<<8)			@  line and reset cursor
	ldr r5, [r6, $28]			@ get max char per line
	b _wtb0

	/* Testing the following block of code, poss cause an abort?
	   if char is a special ie, \n, \r, etc ... then use a branch table to
	   branch to correct 'handle'.
	*/
_spchar:	@ correct way to do it
	@ldr r1, =CharTable
	@ldr r1, [r1, r0, lsl $2]
	@bx r1
		@ experimental way to try it??
	ldr pc, [pc, r0, lsl $2]
	nop
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
	ldr r4, [r6, $28]			@ get max char per line
	ldrb r0, [r10, $1]!			@ get next char
	b _wtb0

	/* Backspace, a somewhat tricky char to deal with causing complexity!!
	   cmp StdOut addr with current string address. If same the cannot delete
	   cmp 1st byte of StdOut. if 0x7f then already deleted back to first 
	   allowable deletable char.
	   Now work way back along string finding first available char (ie not
	   0x7f) to blank out with 0x7f.
	   Then blank out last char in TermBuffer and adjust cursor back 1
	   space.
	*/
_BackSpace:
	ldr r1, =StdOut
	cmp r1, r10				@ if == exit; bs not possible
	ldrneb r0, [r1]
	mov r3, r10				@ copy addr in expectation
	cmpne r0, $0x7f				@ chk if alowed to delete?
	ldreqb r0, [r10, $1]!
	beq _wtb0

	/* ldrb last byte, cmp with 0x7f, if == then go back 1 space untill
	   first byte != with 0x7f, and change byte to 0x7f. A somewhat kludgy
	   way to keep a 'record' of what char's can be deleted. Note current
	   '\b' also has to be blanked out, or when 2 or more '\b' are together
	   (which often happens from user input!) the latter '\b' loop won't
	   detect the '7f' 2 bytes away (remember previous byte is tested so if
	   addr has moved forward 1 byte then previous byte would be '\b' hence
	   why current '\b' has to be 0x7f'd too.
	*/
	ldrb r0, [r3, $-1]!
	mov r1, $0x7f
	strb r1, [r3, $1]			@ blank or have endless loop
_bs1:	cmp r0, r1
	ldreqb r0, [r3, $-1]!
	beq _bs1
	strb r1, [r3]

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
	ldr r5, [r0, $20]			@ fetch CurLine
	ldr r6, [r0, $40]			@ fetch DTermCur
	ldr r7, [r0]				@ fetch address of TermBuffer
	ldr r8, [r0, $32]			@ fetch x (cursor position)
	ldr r9, [r0, $36]			@ fetch y (line number)
	mov r11, r0				@ preserve

_display_line:
	cmp r4, r5				@ reached bottom of screen?
	blls _scroll_screen			
	bl _clear_line

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
	add r6. r6, $2
	bic r6, r6, $(80<<8)			@ looping buffer; stop overflow
	add r8, r8, $1				@ mov x to next place on line
	b _display_char



	/* r0 - r3 scratch, r10 char, r8 = x, r9 = y, r12 = scratch*/
_special_char:
	ldr pc, [pc, r0, lsl $2]		@ branch to correct char handle
	nop
/* DO NOT MOVE CharTable1 3 instruction on from _special_char */ 
CharTable1:
	.word  _null	@0x0
	.word  _noti	@0x1 SOH
	.word  _noti	@0x2
	.word  _noti	@0x3
	.word  _noti	@0x4
	.word  _noti	@0x5
	.word  _noti	@0x6
	.word  _noti	@0x7
	.word  _noti	@0x8
	.word  _noti	@0x9
	.word  _n_line @0xa
	.word  _noti	@0xb
	.word  _noti	@0xc
	.word  _noti	@0xd
	.word  _noti	@0xe
	.word  _noti	@0xf
	.word  _noti	@0x10
	.word  _noti	@0x11
	.word  _noti	@0x12
	.word  _noti	@0x13
	.word  _noti	@0x14
	.word  _noti	@0x15
	.word  _noti	@0x15
	.word  _noti	@0x17
	.word  _noti	@0x18
	.word  _noti	@0x19
	.word  _noti	@0x1a
	.word  _noti	@0x1b
	.word  _noti	@0x1c
	.word  _noti	@0x1d
	.word  _noti	@0x1e
	.word  _noti	@0x1f

_null:
	str r5, [r11, $20]			@ save CurLine
	str r6, [r11, $40]			@ save TermCur
	str r8, [r11, $32]			@ save x (cursor position)
	str r9, [r11, $36]			@ save y (line number)

	ldmfd sp!, {r4 - r11, pc}

_noti:
	nop
_n_line:
	nop
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
	mov r6, r1				@ TermCur = TermStart
	bx lr

_clear_line:
	/* Clear first line of the screen using dma. The control block is
	   preset with defaults for a 80 char with 8x16 fonts screen. 
	   r2,r3,r12 free as scratch registers 
	   r0 = y, r1 =GraphicsAdr
	*/

	ldr r1, =GraphicsAdr

	/* The DEST_AD in the control block is:
		pixels/width * bytes/pixel * no of lines/glyph * y + GraphicsAdr
		1280 * 4 * 16 * y + GraphicsAdr  if defaults values are used
	*/
	mov r2, $1280
	ldr r3, [r1]				@ get GraphicsAdr
	mov r2, r2, lsl $6			@ *64 (*4*16)
	ldr r12, =CB_ClearLine
	mla r1, r0, r2, r3			@ * y + GraphicsAdr
	stmfd sp!, {lr}
	str r1, [r12, $4]
	bl _dma_tfr				@ dma will do the rest
	ldmfd sp!, {pc}				@ return





@@@@@@@@@@@@@@@@ TEMP @@@@@@@@@@
_dma_tfr:
	bx lr
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@ Move to drawing.s @@@@@
	/*r0-r3 = scratch, r10 = char, r8 = x, r9 = y */  
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

/*
Kb_input:
	.rept 0x40
	.hword 0
	.endr
*/
TermInfo:				@ Data array 
	.word TermBuffer	@ #0 pointer to termbuffer
	.word TermBuffer	@ #4 TermStart set to termbuffer at start
	.word 0x00		@ #8 TermCur (bits 14:8 - Line No, 7:0 - cursor
	.word 0x00		@ #12 LastColour (Use to cmp against)
	.word 0x200		@ #16 TermColour (bg,hi nibble:fg,lo nibble)
	.word 0x00		@ #20 Current Screen Line (CurLine)
	.word 0x2c		@ #24 Max Number of Lines default:45 [0-44;0-2c]
	.word 0x50		@ #28 Max number of char/line (LineLength:80)
	.word 0x0		@ #32 Cursloc x
	.word 0x0		@ #36 Cursloc y
	.word 0x0		@ #40 DTermCur for tty_display

BlankLine:			@ Empty blank line to clear 8 pixiles in a row
	.rept 16		@ 128 bit
	.byte 0x0		@ black
	.endr

HelloWorld:
	.asciz "Hello\n\b\b\b\b\bi\nWorld"

StdOut:
	.rept 0x1000
	.byte 0x02
	.endr

Uvga16:
	.incbin "u_vga16.psf"

	/* The Control Block to do a dma transfer has some preset values but others
	   will need to be calculated at run time such as the gpu mem addr 
	   pointing to correct line to blank out. 
	   (TXFR = (hi hw = 16 (y)) (lo hw = 0xa00 (4 (bytes) * 8 (pixels) * 80 (char))
	   (d_stride = 0x1400 (1280 pixels) - 0xa00 (80 char), s_stride = 0)
	*/
	.align 5
CB_ClearLine:			@ Control Block with some preset values
	.word	0x23a		@ TI
	.word	BlankLine	@ #4 SOURCE_AD
	.word	0x00		@ #8 DEST_AD (CurLine * 16)
	.word	0xa0a00		@ #12 TXFR_LEN 
	.word	0xa000000	@ #16 STRIDE 
	.word	0x00		@ #20 NEXTCNBK
	.word	0x00		@ #24 Reserved
	.word	0x00		@ #28 Reserved

	.align 8
TermBuffer:
	.rept 128 * 128
	.hword 0x1
	.endr
@@@ TO DELETE
GraphicsAdr:
	.word 0x51802000
FrameufferInfo:
	.word 1280	@width
	.word 720	@height

