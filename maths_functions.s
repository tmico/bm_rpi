/* maths functions that aren't provided in hardware
 * Note that worst case is around 180 cpu cycles :(
	*/

	.text
	.align 2
	.global _udiv_int

_udiv_int:
	/* _udiv_int: a function to divide 2 unsigned int numbers
	 * dividend is passed through r0, divisor r1.
	 * quotient is returned in r0 and remainder in r1
	*/
	cmp r0, r1
	eormi r0, r0
	eormi r1, r1
	cmp r0, $0				@ test for valid values
	cmpne r1, $0
	bxeq lr
	
	clz r2, r0
	clz r3, r1
	rsb r2, r2, r3
	mov r1, r1, lsl r2
	mov r3, $0x00
_ud:
	cmp r0, r1
	subcss r0, r0, r1
	adc r3, r3, r3
	mov r1, r1, lsr $1
	subs r2, r2, $1
	bpl _ud

	mov r1, r0
	mov r0, r3

	bx lr


	.global _sdiv_int
	
_sdiv_int:
	/* _udiv_int: a function to divide 2 signed int numbers
	 * dividend is passed through r0, divisor r1.
	 * quotient is returned in r0 and remainder in r1
	*/
	
	cmp r0, $0				@ testing sign and 
	rsbmi r0, r0, $0			@  reversing if negative
	movpl r12, $0				@ N flag
	movmi r12, $3
	cmpne r1, $0
	rsbmi r1, r1, $0
	eormi r12, r12, $1			@ if r12[0] != 0 quotient neg
						@ if r12[0] == 0 quotient pos 
						@ if r12[1] != 0 remainder neg
						@ if r12[1] == 0 remainder pos
	cmp r0, r1
	eormi r0, r0
	eormi r1, r1
	cmp r0, $0				@ test for valid values
	cmpne r1, $0
	bxeq lr
	
	clz r2, r0
	clz r3, r1
	rsb r2, r2, r3
	mov r1, r1, lsl r2
	mov r3, $0x00
_sd:
	cmp r0, r1
	subcss r0, r0, r1
	adc r3, r3, r3
	mov r1, r1, lsr $1
	subs r2, r2, $1
	bpl _sd

	tst r12, $2				@ test what sign to return value
	rsbne r1, r0, $0 
	moveq r1, r0
	tst r12, $1
	rsbne r0, r3, $0
	moveq r0, r3

	bx lr
	
