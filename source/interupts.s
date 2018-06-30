	.include "../include/macro.S"
	.section .interupts
	.align 2

	.global _reset
/*===============================================
 * reset
 *=============================================*/
_reset:

	.if DEBUG == 1				@ If debug sym is set then we
	bl _boot_seq				@ ...need to skip seting up the
						@ ...various exception modes
						@ ...to allow gdb debugging
	.else

	/* Populate the vector table with intruction to branch to correct
	 * exception routine
	 */
@--	add r1, pc, $20
	ldr r1, =_vt
	mov r0, $0x0
	ldmia r1!, {r4 - r11} 
	stmia r0!, {r4 - r11}
	ldmia r1!, {r4 - r11} 
	stmia r0!, {r4 - r11}
	b _sp
_vt:
	ldr pc, [pc, $0x18] 			@ = ldr pc, [pc, #24]
	ldr pc, [pc, $0x18]			@ these are the instruction that
	ldr pc, [pc, $0x18]			@ need to populate the first 32 bytes
	ldr pc, [pc, $0x18]			@ of memory; the vector table
	ldr pc, [pc, $0x18]
	ldr pc, [pc, $0x18]
	ldr pc, [pc, $0x18]
	ldr pc, [pc, $0x18]
ExceptionMemLoc:
	.word _reset
	.word _undefined
	.word _swi
	.word _pre_abort
	.word _data_abort
	.word _reserved
	.word _irq_interupt
	.word _fiq_interupt

_sp:
	/* Set up the stack pointers for different cpu modes */
	cpsid iaf, $0x1f		@ Enter System mode
	mov sp, $0x8000			@ set up its stack pointer

	cpsid iaf, $0x11		@ Enter FIQ mode
	mov sp, $0x3000			@ set its stack pointer

	cpsid iaf, $0x12		@ Enter IRQ mode
	mov sp, $0x5000			@ set its stack pointer

	cpsid iaf, $0x13		@ Enter SWI mode
	mov sp, $0x4000			@ set its stack pointer


	cpsid iaf, $0x17		@ Enter Abort mode
	mov sp, $0x3000			@ set its stack pointer

	cpsid iaf, $0x1b		@ Enter Undefined mode
	mov sp, $0x3000			@ set its stack pointer

	cpsie iaf, $0x1f		@ Enter System mode interupts enabled
@--	mov sp, $0x8000			@ set its stack pointer

	/* inititalize peripheral hardware such as uart, gpu framebuffer, 
	 * timer etc while in privileged mode */
	bl _boot_seq

	.endif
	b _main

/*===============================================
 * Undefined
 *=============================================*/
	.global _undefined
_undefined:
	stmfd sp!, {r0 - r12, lr}
	ldr r0, =RegContent
	ldr r1, =UndefinedLable
	mrs r2, spsr
	sub r3, lr, $4				@ when the excepton happend
	bl _kprint
	mov r0, r1
	bl _uart_ctr
ud:
	b ud

/*===============================================
 * SVR/SWI --aka syscall handler
 *=============================================*/
	.global _swi
_swi:
	DMB
	clrex
	srsfd sp!, $0x1f			@ store return state in system
	cpsie iaf, $0x1f			@ ...mode and change to it and
						@ ...re enable interupts
	stmfd sp!, {r0 - r12, lr}

	ldr r5, =Systablesize
	ldr r4, =SysCall
	mov r7, r7, lsl $2			@ shift to get word offset
	cmp r5, r7
	bmi _invalid

	ldr r5, [r4, r7]			@ r7 syscall a la linux
	blx r5					@ branch to correct call
	
	ldmfd sp!, {r0 - r12, lr}		@ prepare for return
	rfefd sp!				@ return

	/* if syscall number out of bounds enter data abort */
_invalid:
	mov r0, $0x17				@ Enter ABORT mode
	msr cpsr, r0				@ ensure irq and fiq are disabled
	b _data_abort

/*===============================================
 * Pre Abort
 *=============================================*/
	.global _pre_abort
_pre_abort:
	ldmfd sp!, {r0 - r12, lr}
	ldr r0, =RegContent
	ldr r1, =PreAbortLable
	mrs r2, spsr
	sub r3, lr, $4				@ when the excepton happend
	bl _kprint
	mov r0, r1
	bl _uart_ctr

	sub r1, pc, $8				@ Informing via uart what...
	ldr r0, =Abort				@ ...exception was triggered
	sub r2, lr, $4
	bl _kprint
	mov r0, r1
	bl _uart_ctr
pa:
	b pa

/*===============================================
 * Data Abort
 *=============================================*/
	.global _data_abort
_data_abort:
	stmfd sp!, {r0 - r12, lr}
	ldr r0, =RegContent
	ldr r1, =DataAbortLable
	mrs r2, spsr
	sub r3, lr, $8				@ when the excepton happend
	bl _kprint
	mov r0, r1
	bl _uart_ctr
da:	
	b da

/*===============================================
 * Reserved/Monitor
 *=============================================*/
	.global _reserved
_reserved:
	stmfd sp!, {r0 - r12, lr}
	ldr r0, =RegContent
	ldr r1, =ReservedLable
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	bl _kprint
	mov r0, r1
	bl _uart_ctr
rsrvd:	
	b rsrvd

/*===============================================
 * IRQ
 *=============================================*/
	.global _irq_interupt
_irq_interupt:		
	@====== new code ======================
	DMB 
	clrex
 	sub lr, lr, $4		@ lr is pc when irq occurs which is 4 higher
	stmfd sp!, {r0 - r12, lr}

	mov r4, $0x20000000
	add r4, r4, $0xb200		@ r12 = &basic_pending
	ldr r7, [r4, $4]		@ r7 = pending_1
	ldr r8, [r4, $8]		@ r8 = pending_2
	ldr r6, [r4]			@ r6 = pending_0
	ldr r5, =IrqHandler
	/* priority order: pending_1, pending_2, pending_0 */
_pend1:
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
	b _pend1
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

	@=======================================================
	.global IrqHandler

IrqHandler:			@ 96 irq handlers pointers
	.rept 96
	.word 0
	.endr

	.global _fiq_interupt
_fiq_interupt:
	b _fiq_interupt


/* IRQ handlers. */
	
	.global _arm_timer_interupt
_arm_timer_interupt:	
	/* First clear the pending interupt */
	stmfd sp!, {r0 - r12, lr}
	mov r2, $0x20000000			@ timer base addr = 0x2000b40c
	add r2, r2, $0xb000
	mov r5, $1
	str r5, [r2, $0x40c]
	ldr r3, =LedOnOff
	ldr r1, [r3]
	mov r0, $16
	eor r1, r1, $1
	str r1, [r3]
	bl _set_gpio

	/* here for debugging */
	ldr r0, =B
	bl _kprint

	ldmfd sp!, {r0 - r12, pc}

/* =========== End of interupt service routines ====== */


@=====================================================
@ Most of data bellow is just here to help debugging and
@ will be cut at some time
@=====================================================
.data
.align 2
	.global RegContent
	.global SwiLable
LedOnOff:
	.word	0x0


	.global A
A:
	.asciz "IRQ"
B:
	.asciz "ARM_TIMER "
	
RegContent:
	.ascii "\nException: %s\ncpsr: %x\nsp: %x\nr0: %x\nr1: %x"
	.ascii "\nr2: %x\nr3: %x\nr4: %x\nr5: %x\nr6: %x\nr7: %x\nr8: %x\nr9: %x\nr10: %x"
	.asciz "\nr11: %x\nr12: %x\nlr: %x\n"
SwiLable:
	.asciz "SVR/SWI"
PreAbortLable:
	.asciz "Pre Abort"
DataAbortLable:
	.asciz "Data Abort"
UndefinedLable:
	.asciz "Undefined"
ReservedLable:	
	.asciz "Reserved"
Abort:
	.asciz "PC is %x\nlr is %x\n"

