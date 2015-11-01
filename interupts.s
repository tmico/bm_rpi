/* Bellow are the handlers for each exception, obviously unfinshed!!!*/
	.section .interupts
	.global _undefined
_undefined:
	b _undefined

	.global _swi
_swi:
	b _swi

	.global _abort
_abort:
	b _abort

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

	ldr r1, =0x2000b200			@ basic pending register
	ldm r1, {r2-r4}				@ load multiple in one go
	ldr r5, =IrqHandler
_irq_source:
	and r8, r2, $100			@ If pending_1 has IRQ save it
	and r9, r2, $200			@ If pending_2 has IRQ save it
	bics r0, r2, $0x300			@ mask off and test bits 8,9
	beq _tst_bit8
	mov r6, $64
_irq_bit:
	/* source of irq in r0	*/
	clz r1, r0				@ preserve r0 for testing 
	rsb r1, r1, $31				@ calculate bit position
	add r2, r6, r1
	ldr r7, [r5, r2, lsl $2]
	blx r7		
	mov r2, $1
	mov r2, r2, lsl r1
	bics r0, r0, r2
	bne _irq_bit
	teq r8, $100				@ something in pending_1?
	beq _tst_bit8
	teq r9, $200
	beq _tst_bit9				@ something in pending_2?
	ldmfd sp!, {r0-r12, pc}^		@ return from interrupt
 _tst_bit8:
	teq r8, $0x100
	bne _tst_bit9
	bic r8, r8, $0x100			@ test bit 8 and clear if set
	bic r3, r3, $((1<<7)|(1<<9)|(1<<10))	@ clear duplicate interupts
	bic r3, r3, $((1<<18)|(1<<19))		@ also set in basic
	moveq r0, r3
	moveq r6, $0
	beq _irq_bit
_tst_bit9:
	teq r9, $0x200				@ tst bit 9 and clear if set
	bic r9, r9, $0x200
	bic r4, r4, $((31<<21))			@ clear duplicate interupts
	bic r4, r4, $((1<<30))			@	also set in basic
	moveq r0, r4
	moveq r6, $32				@ r6 + bit position = irq no
	bal _irq_bit

/* IRQ handlers. 
initial idea is routines wishing to use interupts need to place pointers
in mem using this funtion which in turn will handle clearing source and do
other stuff im not sure what less explain it!!!
 thinking r0 will be IRQ number r1 will, be pc of where to branch to 
TO DO !!!	*/

	
	.global _arm_timer_interupt
_arm_timer_interupt:	
	/* First clear the pending interupt */
	mov r11, $0x20000000			@ timer base address
	add r11, r11, $0xb000
	mov r10, $1
	str r10, [r11, $0x40c]
	ldr r11, = IrqService
	ldr r10, [r11]
	push {r0-r1, lr}
	mov r12, $1
	eor r1, r10, r12
	str r1, [r11]
	mov r0, $16
	bl _set_gpio
	pop {r0-r1, pc}
.data
.align 2
	.global IrqHandler

IrqHandler:			@ 84 irq handlers pointers
	.word	@ IRQ 1 
	.word	@ IRQ 2 
	.word	@ IRQ 3 
	.word	@ IRQ 4 
	.word	@ IRQ 5 
	.word	@ IRQ 6 
	.word	@ IRQ 7 
	.word	@ IRQ 8 
	.word	@ IRQ 9 
	.word	@ IRQ 10
	.word	@ IRQ 11
	.word	@ IRQ 12
	.word	@ IRQ 13
	.word	@ IRQ 14
	.word	@ IRQ 15
	.word	@ IRQ 16
	.word	@ IRQ 17
	.word	@ IRQ 18
	.word	@ IRQ 19
	.word	@ IRQ 20
	.word	@ IRQ 21
	.word	@ IRQ 22
	.word	@ IRQ 23
	.word	@ IRQ 24
	.word	@ IRQ 25
	.word	@ IRQ 26
	.word	@ IRQ 27
	.word	@ IRQ 28
	.word	@ IRQ 29
	.word	@ IRQ 30
	.word	@ IRQ 31
	.word	@ IRQ 32
	.word	@ IRQ 33
	.word	@ IRQ 34
	.word	@ IRQ 35
	.word	@ IRQ 36
	.word	@ IRQ 37
	.word	@ IRQ 38
	.word	@ IRQ 39
	.word	@ IRQ 40
	.word	@ IRQ 41
	.word	@ IRQ 42
	.word	@ IRQ 43
	.word	@ IRQ 44
	.word	@ IRQ 45
	.word	@ IRQ 46
	.word	@ IRQ 47
	.word	@ IRQ 48
	.word	@ IRQ 49
	.word	@ IRQ 50
	.word	@ IRQ 51
	.word	@ IRQ 52
	.word	@ IRQ 53
	.word	@ IRQ 54
	.word	@ IRQ 55
	.word	@ IRQ 56
	.word	@ IRQ 57
	.word	@ IRQ 58
	.word	@ IRQ 59
	.word	@ IRQ 60
	.word	@ IRQ 61
	.word	@ IRQ 62
	.word	@ IRQ 63
	.word	@ IRQ 64
	.word	@ IRQ 65
	.word	@ IRQ 66
	.word	@ IRQ 67
	.word	@ IRQ 68
	.word	@ IRQ 69
	.word	@ IRQ 70
	.word	@ IRQ 71

IrqService:
	.word	0x1		@ Address of routine that set timer interupt
