	/* Currently as it stands the vector table has to be placed at mem location
	 * starting 0x0. If kernel's entry point is anywhere else but there then
	 * a bit of a kludgyness is needed to put the working instructions there.
	 * See .init section of main. This is an attempt to find a more
	 * eligant solution that would use the 'branch' opp code rather than
	 * 'ldr pc' currently used. advantage of 'branch' is its faster execution
	 * time
	*/

	.global _init
	.global _start
_start:	
	b _init
	.rept 32
	.word 0xeafffffe
	.endr
_init:	
	ldr r1, =_lable				@ Put absolute addr in r1
	mov r0, $0xea000000			@ 0xea = branch always
	mov r1, r1, lsr $2			@ the addr part is a right shiffted value
	orr r0, r0, r1
	ldr r2, _start
	str r0, [r2]
	b _start

space_waste:
	.rept 32
	.word 0xff
	.endr

_lable:
	nop
