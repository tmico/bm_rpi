	.section .interupts
	.align 2
/* Bellow are the handlers for each exception, obviously unfinshed!!!*/

	.global _reset
_reset:

	/* Ensure we are in supervisor mode */
	mov r0, $0x13
	msr cpsr_c, r0

	/* Set up the stack pointers for different cpu modes */
	mov r0, $0x11			@ Enter FIQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x3000			@ set its stack pointer

	mov r0, $0x12			@ Enter IRQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x5000			@ set its stack pointer

	mov r0, $0x13			@ Enter SWI mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x4000			@ set its stack pointer

	bl _boot_seq

	mov r0, $0x17			@ Enter ABORT mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x3000			@ set its stack pointer

	mov r0, $0x1b			@ Enter UNDEFINED mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x3000			@ set its stack pointer

	mov r0, $0x10
	msr cpsr, r0			@ User mode | fiq/irq enabled
	mov sp, $0x8000

	/* inititalize peripheral hardware such as uart, gpu framebuffer, 
	 * timer etc */

	b _start

	.global _undefined
_undefined:
	ldr r0, =RegContent
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	ldr r3, =UndefinedLable
	bl _kprint
	mov r0, r1
	bl _uart_ctr
ud:
	b ud

	.global _swi
_swi:
	stmfd sp!, {r0 - r12, lr}	 	@ unlike IRQ/FIQ lr is pc +4 
	clrex
	/* GOING to print to contents of all the registers inc spsr - 
		for degbuging reasons */
	/*
	mrs r0, cpsr
	bic r0, r0, $(1<<7)			@ re-enable interupts
	bic r0, r0, $(1<<6)			@ re-enable fiq
	msr cpsr, r0
	*/

	ldr r4, =SysCall
	ldr r5, [r4, r7, lsl $2]		@ r7 syscall a la linux
	blx r5					@ branch to correct call
	
	mrs r0, cpsr
	orr r0, r0, $(1<<7)			@ disable interupts
	orr r0, r0, $(1<<6)			@ disable fiq
	msr cpsr, r0
	str r2, [r0]				@ clear lock
ldmfd sp!, {r0-r12, pc}^		@ return from svr/swi

	.global _pre_abort
_pre_abort:
	ldr r0, =RegContent
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	ldr r3, =PreAbortLable
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

	.global _data_abort
_data_abort:
da:	
	ldr r0, =RegContent
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	ldr r3, =DataAbortLable
	bl _kprint
	mov r0, r1
	bl _uart_ctr
	b da

	.global _reserved
_reserved:
	ldr r0, =RegContent
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	ldr r3, =ReservedLable
	bl _kprint
	mov r0, r1
	bl _uart_ctr
rsrvd:	
	b rsrvd

/* IRQ. The PI has NO interupt vector module. It has 3 pending registers with
   some IRQ from pending_1 and pending_2 also duplicated in pending_basic. Bits
   8 and 9 in pending_basic are not IRQ's but status bits to inform if there 
   are any IRQ's pending in pending_1 and/or pending_2 set. The 'duplicates'
   are NOT tacken into account for these 2 status bits.
	bit 8 - pending_1
	bit 9 - pending_2
   Bits 8 and 9 are thus 'There are more interupts in other register[s]'
 * Based on suggestion in BCM2835 manual pg 111 with amendments
   to speed things up. sequence is 1) test for bits 8 and 9
   and branch if only bit 8 or 9 is set to mask off duplicates
   2) process which irq has triggerd, set branching address
   3) branch to requestor and clear flag.
   4) when back re-test in remote event that 2 or more irq'a
   were triggered at the same time 	
 * The branching address holds the address to branch to using blx. 
   The address is a little convaluted. Each IRQ has its own handling address 
	which is:
	IrqHandler (base address) + IRQ number
	IRQ number is same as found in BCM2835 manual. And worked out by adding
	the bit position to the offset of its pending register so:
	pending_1 starts at offset #0 + [bit position] (IRQ 1-31)
	pending_2 starts at offset #32 + [bit position] (IRQ 32-63)
	basic pending starts at offset #64 + [bit position] (IRQ 64-71)
*/
	.global _irq_interupt
_irq_interupt:		

	sub lr, lr, $4		@ pc -> lr when interupt occurs which is $4
				@  higher than instruction we want to return to
	stmfd sp!, {r0-r12, lr}	
	clrex

	mov r0, $0x20000000			@ basic pending register
	add r0, r0, $0xb200
	ldr r8, [r0]
	ldr r7, =IrqHandler
_irq_source:
	mov r6, $64
	and r9, r8, $0x300			@ If pending_1/2 has IRQ save it
	bics r10, r8, $0x300			@ mask off and test bits 8,9
	beq _tst_bit89
_irq_bit:
	/* source of irq in r10	*/
	clz r1, r10				@ preserve r10 for testing 
	add r8, r6, r1				@  r1 is scratch
	ldr r0, [r7, r8, lsl $2]		@ r8*4 = offset 
	mov r8, $(1<<31)
	bic r10, r10, r8, lsr r1
	blx r0		
	cmp r10, $0
	bne _irq_bit
	tst r9, $0x100				@ something in pending_1?
	bne _bit8
	tst r9, $0x200
	bne _bit9				@ something in pending_2?
	ldmfd sp!, {r0-r12, pc}^		@ return from interrupt
_tst_bit89:
	teq r9, $0x100
	bne _bit9
_bit8:	
	ldr r10, [r11, $4]
	mov r6, $0
	bic r9, r9, $0x100			@ clear bit 8 if set
	bic r10, r10, $(13<<7)			@ clear duplicate interupts
	bic r10, r10, $(3<<18)			@  also set in basic	
	beq _irq_bit
_bit9:
	ldr r10, [r11, $8]
	moveq r6, $32				@ r6 + bit position = irq no
	bic r9, r9, $0x200
	bic r10, r10, $(31<<21)			@ clear duplicate interupts
	bic r10, r10, $(1<<30)			@	also set in basic
	bal _irq_bit

	.global IrqHandler

IrqHandler:			@ 96 irq handlers pointers
	.rept 96
	.word 0
	.endr

	.global _fiq_interupt
_fiq_interupt:
	b _fiq_interupt


/* IRQ handlers. 
initial idea is routines wishing to use interupts need to place pointers
in mem using this funtion which in turn will handle clearing source and do
other stuff im not sure what less explain it!!!
 thinking r0 will be IRQ number r1 will, be pc of where to branch to 
TO DO !!!	*/
	
	.global _arm_timer_interupt
_arm_timer_interupt:	
	/* First clear the pending interupt */
	mov r2, $0x20000000			@ timer base addr = 0x2000b40c
	add r2, r2, $0xb000
	mov r5, $1
	str r5, [r2, $0x40c]
	ldr r3, =LedOnOff
	ldr r1, [r3]
	mov r0, $16
	mov r4, lr				@ preserv lr
	eor r1, r1, $1
	str r1, [r3]
	bl _set_gpio
	ldr r0, =A
	bl _uart_ctr
	bx r4

/* =========== End of interupt service routines ====== */

/* SVR/SWI Handlers
*/

.data
.align 2

LedOnOff:
	.word	0x0
A:
	.asciz "A"
	
RegContent:
	.ascii "\ncpsr: %x\npc_old: %x\nException: %s\nr12: %x\nr11: %x"
	.ascii "\nr10: %x\nr9: %x\nr8: %x\nr7: %x\nr6: %x\nr5: %x\nr4: %x\nr3: %x\nr2: %x"
	.asciz "\nr1: %x\nr0: %x\n"
SwiLable:
	.asciz "SRV/SWI"
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








