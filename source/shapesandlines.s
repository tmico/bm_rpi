/* Bresenhams's Allgorithm for staight lines*/

	.text
	.global _draw_line

_draw_line:
	stmfd sp!,  {r4-r12, lr}		@ need to also preserve r0-r3
	mov r4, r0
	mov r5, r1
	mov r6, r2
	mov r7,	r3
	subs r10, r2, r0			@ delta_x
	rsbmi r10, r10, $0x00			@ delta_x needs to be positive
	mov r8, $0x01				@ inc x value
	rsbmi r8, r8, $0x00			@ not 0 = -1

	subs r11, r3, r1			@ delta_y
	rsbmi r11, r11, $0x00
	mov r9, $0x01
	rsbmi r9, r9, $0x00

	cmp r10, r11				@ assertain the driving axis
	bmi _y_axis

_x_axis:
	blx  r12 				@ plot x0,y0 found in r0,r1
	rsb r7, r10, r11, lsl $1		@ r7 = p_k = 2delta_y - delta_x
	mov r6, r10				@ r6 = delta_x for counter
_x_loop:
	cmp r7, $0
	add r7, r7, r11, lsl $1			@ if <0 add 2delta_y; y=y
	subpl r7, r7, r10, lsl $1		@ else add 2delta_y - 2delta_x
	add r4, r4, r8				@ inc x
	addpl r5, r5, r9			@ if > 0 y=y+1
	
	mov r0, r4
	mov r1, r5

	ldmfd sp, {r12}				@ no write back
	blx r12
	subs r6, r6, $1				@ delta_x = -1 ; line finished
	bpl  _x_loop

	ldmfd sp!, {r4-r11, pc}

_y_axis:
	blx r12 				@ plot x0,y0 found in r0,r1
	rsb r7, r11, r10, lsl $1		@ r7 = p_k = 2delta_x - delta_y
	mov r6, r11				@ r6 = 2delta_y for counter
_y_loop:
	cmp r7, $0
	add r7, r7, r10, lsl $1			@ if <0 add 2delta_x; x=x
	subpl r7, r7, r11, lsl $1		@ else add 2delta_x - 2delta_y
	addpl r4, r4, r8			@ inc x if >0
	add r5, r5, r9				@ y=y+1
	
	mov r0, r4
	mov r1, r5
	ldmfd sp, {r12}				@ no write back
	blx r12
	subs r6, r6, $1				@ delta_y = -1 ; line finished
	bpl  _y_loop

	ldmfd sp!, {r4-r12, pc}
