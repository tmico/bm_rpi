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
	ldr r11, [r10, $0x08]			@ offset that holds bitmap
						@  data offset.
	mov r5, $0x00				@ r5 to be copy of _fg_colour
	mov r6, r0				@ x starting point
	add r7, r1, r9				@ y starting point
_P1:
	add r10, r10, r11			@ r10 holds start of pic loc
	mov r11, r6				@ copy starting point of width

	ldrb r4, [r10], $1			@ easyier to ldr bytes with
	ldrb r3, [r10], $1			@  non word aligned data1
	ldrb r0, [r10], $1			@  load scheduling by unrolling

_Lpic:
	orr r2, r3, r4, lsl $8			
	orr r0, r0, r2, lsl $8
	teq r0, r5				@ Only want to branch if diff
	movne r5, r0				@ preserve new _fg_colour
	blne _fg_colour				@ set new _fg_colour if new
	mov r0, r6				@ r6 and r7 are coordinates
	mov r1, r7
	bl _set_pixel32

_Lwidth:
	subs r8, r8, $1				@ counter based on width
	addpl r6, r6, $1
	ldrplb r4, [r10], $1			@ easyier to ldr bytes with
	ldrplb r3, [r10], $1			@  non word aligned data1
	ldrplb r0, [r10], $1			@ load scheduling by preloading
	bpl _Lpic
	submi r8, r6, r11			@ reset counter & starting pixel
	movmi r6, r11
	submi r7, $1
	submis r9, r9, $1			@ counter for height. if == 0
						@  then pic displayed
	ldrplb r4, [r10], $1			@ easyier to ldr bytes with
	ldrplb r3, [r10], $1			@  non word aligned data1
	ldrplb r0, [r10], $1			@ load scheduling by preloading
	bpl _Lpic

	ldmfd sp!, {r4 - r11, pc}		@ Exit	

