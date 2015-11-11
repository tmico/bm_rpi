/* Funtion to display fabienne's picture on screen. The format is a bitmap
 * 24bit picture with the 1st 2bytes of the header stripped off to make rest of
 * header word aligned. ie it makes it easier to load varous values such as 
 * width, height contained in the header into the registers. */

	.global _display_pic

 _display_pic:
	stmfd sp!, {r4 - r11, lr}

	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - offset that holds
						@  width and height
	teq r0, $0x00
	teqeq r1, $0x00				@ Test for arguments given
	beq _P0

	mov r6, r0				@ x starting point
	mov r7, r1				@ y starting point
_P1
	ldr r11, [r10, $0x08]			@ offset that holds bitmap
						@  data offset.
	add r10, r10, r11			@ r10 holds start of pic loc
	mov r12, r8				@ copy for counter of width
	mov r11, r6				@ copy starting point of width
	mov r5, $0x00				@ r5 to be copy of _fg_colour


_Lpic:
	ldrb r4, [r10], $1			@ easyier to ldr bytes with
	mov r0, r4				@  non word aligned data
	ldrb r4, [r10], $1
	orr r0, r4, lsl $8
	ldrb r4, [r10], $1
	orr r0, r4, lsl $16
	teq r0, r5				@ Only want to branch if diff
	movne r5, r0				@ preserve new _fg_colour
	blne _fg_colour				@ set new _fg_colour if new
	mov r0, r6				@ r6 and r7 are coordinates
	mov r1, r7
	bl _set_pixel

_Lwidth:
	subs r8, r8, $1				@ counter based on width
	addpl r6, r6, $1
	movmi r6, r11				@ reset starting width if == 0
	movmi r8, r12
	submi r7, $1
	submis r9, r9, $1			@ counter for height. if == 0
						@  then pic displayed
	bpl _Lpic

	ldmfd sp!, {r4 - r11, pc}		@ Exit	

_P0

	rsb r6, r8, $0x500
	mov r6, r6, lsr $1			@ starting pixel location to
	rsb r7, r9, $0x2d0			@  display pic centre screen
	mov r7, r7, lsr $1			@  r6 - width, r7 - height
	add r7, r7, r9				@ bmp pics are bottom up

	b _P1
