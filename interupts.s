	.section .interupts
	.align 2
/*
	Instruction table to load into memory 0x00
	The kernel is loaded to mem loc 0x8000. The arm system jumps to these
	addresses when there is an exception:
	0x00 : reset
	0x04 : undifined instruction
	0x08 : software interupt (svr)
	0x0c : pre abort
	0x10 : data abort
	0x14 : reserverd
	0x18 : IRQ
	0x1c : FIQ
	The insruction table is used to put the correct branch instructions 
	(ie, if there is an interupt, the intruction at 0x18 will be
	[b <_interupt_handler_lable>] or [ldr pc, =_irq_interupt])
	into the correct memory location
*/
/* Bellow are the handlers for each exception, obviously unfinshed!!!*/


	.global _reset
_reset:

	/* Ensure we are in supervisor mode */
	mov r0, $0x13
	msr cpsr_c, r0

	/* populate 0x00 to 0x1c with ldr pc instructions to jump to correct
	   handler. pc is loaded the correct address found at pc + 5instruction
	   mem block 0x20 to 0x38 holds these correct addresses
	*/   
	mov r1, $0x8000
	mov r0, $0x0000
	ldmia r1!, {r4 - r11}
	stmia r0!, {r4 - r11}
	ldmia r1!, {r4 - r11}
	stmia r0!, {r4 - r11}

	/* Enable branch prediction in System Control coprocessor (CP15) and
	/*  enable instruction cache  
	/* mcr p15, 0, <rd>, c1, c0, 0  ; Read Control Register configuration
	/* mrc p15, 0, <rd>, c1, c0, 0  ; write Control Register configuration
	/*  bits [11] - branch prediction, [12] - L1 intruction cache
	mcr p15, 0, r0, c7, c5, 6	@ flush branch target cache
	mcr p15, 0, r0, c7, c5, 4	@ flush prefetch buffer
	mcr p15, 0, r0, c7, c5, 0	@ invalidate I cache and flush btac
	*/

	mrc p15, 0, r0, c1, c0, 0	@ read control reg of p15
	mov r1, $0x1800			@ bits 11 and 12 enable I and Z
	orr r0, r0, r1
	bic r0, r0, $0x1		@ Disable the mmu (M)
	bic r0, r0, $0x2		@ Disable strict alignment (A)
	bic r0, r0, $0x4		@ Disable unified/Data cache (C)
	bic r0, r0, $0x80		@ Little endian system (B)
	bic r0, r0, $0x100		@ Disable system protection (S)
	bic r0, r0, $0x200		@ Disable rom protection (R)
	bic r0, r0, $0x2000		@ clear = low exception vector (V)
	mcr p15, 0, r0, c1, c0, 0	@ write to control reg of c15

	/* Set VBAR to zero (reset value) */
	mov r0, $0x0
	mcr p15, 0, r0, c12, c0, 0

	mov r0, $0x00
	mcr p15, 0, r0, c7, c7, 0	@ invalidate both caches and flush btac

	/* Set up the stack pointers for different cpu modes */

	mov r0, $0x11			@ Enter FIQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x8000			@ set its stack pointer

	mov r0, $0x12			@ Enter IRQ mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x8000			@ set its stack pointer

	mov r0, $0x13			@ Enter SWI mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x8000			@ set its stack pointer

	mov r0, $0x17			@ Enter ABORT mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0x8000			@ set its stack pointer

	mov r0, $0x1b			@ Enter UNDEFINED mode
	msr cpsr, r0			@ ensure irq and fiq are disabled
	mrs r0, cpsr
	orr r0, r0, $0xc0
	msr cpsr, r0
	mov sp, $0xf0000		@ set its stack pointer

	mov r0, $0x10
	msr cpsr, r0			@ User mode | fiq/irq enabled
	mov sp, $0xF8000

	/*	Enable various interupts	*/
	/* Clear all enable interupts first	*/

	mov r0, $0x20000000		@ Base irq address
	add r0, r0, $0xb000
	mvn r1, $0
	str r1, [r0, $0x21c]
	str r1, [r0, $0x220]
	str r1, [r0, $0x224]
	mov r1, $0
	str r1, [r0, $0x20c]		@ disable all FIQ
	/* arm timer */
	ldr r1, [r0, $0x218]		@ Only concerned with timer at this time
	orr r1, r1, $0x1
	str r1, [r0, $0x218]
	ldr r2, =_arm_timer_interupt	@ loading loc of lable
	ldr r3, =IrqHandler
	str r2, [r3, $380]		@ timer handler has 95*4 offset
	/*	End of enable interupts		*/
	b _start

	.global _undefined
_undefined:
	b _undefined

	.global _swi
_swi:

	stmfd sp!, {r0-r12, lr}	 	@ unlike IRQ/FIQ lr is pc +4 needs checking
	/* going to print to contents of all the registers inc spsr - 
		for degbuging reasons
	*/

	stmfd sp!, {r0 - r12}			@ load stack with args to print
	ldr r0, =RegContent
	mrs r1, spsr
	sub r2, lr, $4				@ when the excepton happend
	ldr r3, =SwiLable
	bl _kprint
	bl _write_tfb
	cmp r0, $0				@ clear screen?
	blne _clrscr_dma0
	bl _display_tfb
	ldmfd sp!, {r0-r12, pc}^		@ return from svr/swi

	.global _pre_abort
_pre_abort:
	b _pre_abort

	.global _data_abort
_data_abort:
	b _data_abort

	.global _reserved
_reserved:
	b _reserved

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

	mov r11, $0x20000000			@ basic pending register
	add r11, r11, $0xb200
	ldr r8, [r11]
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
	ldr r3, = LedOnOff
	ldr r1, [r3]
	mov r0, $16
	mov r4, lr				@ preserv lr
	eor r1, r1, $1
	str r1, [r3]
	bl _set_gpio
	bx r4
.data
.align 2

	.global IrqHandler

IrqHandler:			@ 96 irq handlers pointers
	.rept 96
	.word 0
	.endr
LedOnOff:
	.word	0x0
RegContent:
	.asciz "\ncpsr: %d\npc_old: %d\nException: %s\nr12: %d\nr11: %d\n \
r10: %d\nr9: %d\nr8: %d\nr7: %d\nr6: %d\nr5: %d\nr4: %d\nr3: %d\nr2: %d\n \
r1: %d\nr0: %d"
SwiLable:
	.asciz "SRV/SWI"
