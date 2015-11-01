/* Bresenhams's Allgorithm for staight lines
 * Designed in 60's to draw a straight line on digital plotters, but has 
   found wide spread usage in computer graphics as it is fast, using interger
   only (can use float but why would you want to?)
 * The algorithm is:
		delta_x = xi-x1			
		delta_y = yi-y1
		k = 0
		p_k = 2delta_y - delta_x
		plot (x1,y1)
		for x < xi: 
			if p_k < 0:
				plot (x_k +1, y_k)
				p_k = p_k + 2delta_y
			else:
				plot (x_k +1, y_k +1)
				p_k = p_k + 2delta_y - 2delta_x
			x = x +1:

 * The algorithm only computes for the first octant of a circle however, but
   it is trivial to adapt and ammend depending on conditions tested for, to have
   it working for any octant.
	delta_[x,y] in the algorithm needs to be positive but a simple conditional 
	RSB from zero will convert to the two's compliment. eg -2 becomes 2.

	x is the driving axis. The driving axis needs to be the larger of the
	two axis. CMP delta_x, delta_y can be used to determine the driving axis
	or if the line is a perfect 45", horizontal or vertical in which case
	the algorithm can be skiped for a much simpler stepping instruction if 
	thought the gain in speed is worth it considering the frequency it will
	be used is very low.
*/

/* _draw_line([x,y],[xi,yi]) takes four arguments that are the xy coordinates
	for the point of origin of the line to its end point. [x,y] start point
	[xi,yi] end point.
	As it ierates over the algorithm it will call _set_pixel() to display
	the line as each pixel coordinate is calculated
*/

	.text
	.global _draw_line

_draw_line:
	stmfd sp!,  {r0-r12, lr}		@ need to also preserve r0-r3

	subs r10, r0, r2			@ delta_x
	rsbmi r10, r10, $0			@ delta_x needs to be positive
	movpl r8, $1				@ inc x value
	mvnmi r8, $0				@ not 0 = -1

	subs r11, r1, r3			@ delta_y
	rsbmi r11, r11, $0
	movpl r9, $1
	mvnmi r9, $0

	cmp r10, r11				@ assertain the driving axis
	bmi _y_axis

_x_axis:
	ldmfd sp!, {r4-r7}			@ mov r0-r3 into r4-r7
	bl _set_pixel				@ plot x0,y0 found in r0,r1
	rsb r7, r10, r11, lsl $1		@ r7 = p_k = 2delta_y - delta_x
	mov r6, r10				@ r6 = 2delta_x for counter
_x_loop:
	cmp r7, $0
	add r7, r7, r11, lsl $1			@ if <0 add 2delta_y; y=y
	subpl r7, r7, r10, lsl $1		@ else add 2delta_y - 2delta_x
	add r4, r4, r8				@ inc x
	addpl r5, r5, r9			@ if > 0 y=y+1
	
	mov r0, r4
	mov r1, r5
	bl _set_pixel
	subs r6, r6, $1				@ delta_x = -1 ; line finished
	bpl  _x_loop
	ldmfd sp!, {r4-r12, pc}

_y_axis:
	ldmfd sp!, {r4-r7}			@ mov r0-r3 into r4-r7
	bl _set_pixel				@ plot x0,y0 found in r0,r1
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
	bl _set_pixel
	subs r6, r6, $1				@ delta_y = -1 ; line finished
	bpl  _y_loop
	ldmfd sp!, {r4-r12, pc}
