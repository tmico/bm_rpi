	.text
	.align 2
	.global _mmu_tlb

_mmu_tlb:	
	ldr r0, =Tlb_l1_base
	mov r1, $512 				@ 512 entries for sdram
	ldr r3, =TlbValNormal
	ldr r2, [r3]
	str r2, [r0], $4
_1st:	
	subs r1, $1
	addne r2 , r2, $0x100000
	str r2, [r0], $4
	bne _1st
	ldr r3, =TlbValDevice
	ldr r2, [r3]
	mov r1, $0x600				@ 2048 - 512 = 0x600 entries left
	str r2, [r0], $4
_2nd:
	subs r1, r1, $1
	addne r2, r2, $0x100000
	str r2, [r0], $4
	bne _2nd
	bx lr
	

	.data
	.align 2
	
TlbValNormal:
	.word 0x00000c0a			@ CB=Non Cachable, AP=rw:rw, D=0

TlbValDevice:
	.word 0x20000c06			@ device memory mapping...
						@ ... starting from 0x200000
	
	.global Tlb_l1_base
	.align 14		@16k boundry

Tlb_l1_base:
	.rept 2048
	.word 0
	.endr
