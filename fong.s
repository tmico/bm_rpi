/* routine to move Fabiennes picture around the screen, Bouncing around 
 * the edges 
 */

	.global _display_pic

 _display_pic:
	ldmfd sp!, {r4 - r11}

	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - offset that holds
						@  width and height
	mov r0, $0x500
	mov r1, $0x2d0				@ height of screen is 0x2d0 but
						@  want to reserv top 32 lines
						@  for text.

	rsb r6, r8, r0
	mov r6, r6, lsr $1			@ starting pixel location to
	rsb r7, r9, r1				@  display pic centre screen
	mov r7, r7, lsr $1			@  r6 - width, r7 - height
	add r7, r7, r9				@ bmp pics are bottom up
	ldr r11, [r10, $0x08]			@ offset that holds bitmap
						@  data offset.
	add r10, r10, r11			@ r10 holds start of pic loc
	add r8, r8, $1
	mov r12, r8				@ copy for counter of width
	mov r11, r6				@ copy starting point of width
_Lpic:
	ldrb r4, [r10], $1			@ easyier to ldr bytes with
	mov r0, r4				@  non word aligned data
	ldrb r4, [r10], $1
	orr r0, r4, lsl $8
	ldrb r4, [r10], $1
	orr r0, r4, lsl $16
	bl _fg_colour
	mov r0, r6				@ r6 and r7 are coordinates
	mov r1, r7
	bl _set_pixel

_Lwidth:
	subs r8, r8, $1				@ counter based on width
	addne r6, r6, $1
	moveq r6, r11				@ reset starting width if == 0
	moveq r8, r12
	subeq r7, $1
	subeqs r9, r9, $1			@ counter for height. if == 0
						@  then pic displayed
	bne _Lpic

