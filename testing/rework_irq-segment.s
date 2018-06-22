/*
 * reworking the irq interrupt for the pi. An attempt to improve performance
 * and deal with potential race conditions
 */

 _irq_interupt:
	@--DMB here
	clrex
 	sub lr, lr, $4		@ lr is pc when irq occurs which is 4 higher
	stmfd sp!, {r0 - r12, lr}
	mov r4, $0x20000000
	add r4, r4, $0xb200		@ r12 = &basic_pending
	ldrd r6, r7, [r4]		@ r0 = pending_0, r1 = pending_1
	ldr r8, [r4, $8]		@ r2 = pending_2
	ldr r5, =IrqHandler
	/* priority order: pending_1, pending_2, pending_0 */
_irq0:
	bic r7, r7, $(13 << 7)
	bics r7, r7, $(3 << 18)		@ clr duplicate bits
	beq _pend2
	clz r10, r7
	mov r9, $0
_irq1:
	add r0, r9, r10, lsl $2
	ldr lr, [r5, r0]		@ lr = irq handler routine
	blx lr				@ jump to service irq

	/* need to reload and retest in event of another interupt occuring
	 * whilst servicing previous int - bits in pending reg can still be
	 * set despite irq bit disabled in cpsr
	 */
	ldrd r6, r7, [r4]		@ r0 = pending_0, r1 = pending_1
	ldr r8, [r4, $8]		@ r2 = pending_2
	b _irq0
_pend2:
	bic r7, r8, $(31 << 21)
	bics r7, r7, $(1 << 30)		@ clr duplicates
	mov r9, $32
	clz r10, r7
	bne _irq1
_pend0:
	bics r7, r6, $0x300		@ clr and tst if any pending
	clz r10, r7
	mov r9, $256			@ 64 * 4
	bne _irq1
	/* return from exception */
	ldmfd sp!, {r0 - r12, pc}^
