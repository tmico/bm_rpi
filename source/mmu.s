/* A simple and basic mmu setup to enable primarily memory to be maked as normal
 * (Needed if ldrex/strex are to be used) and allow the data cache to be turned
 * on.
	c2 is the register in p15
	Translation Table register 0 allowes 16k boundries
	[31:14-N] physical address of first level translation table
	[13-N:5] SBZ
	[4:3] RGN b11 = Write-back, No Allocate on Write.
	  N is boundry size of Translation table base 0. 0=16k 7=128bytes
	MRC p15, 0, <Rd>, c2, c0, 0    ; Read Translation Table Base Register 0
	MCR p15, 0, <Rd>, c2, c0, 0    ; Write Translation Table Base Register 0

	Translation Table register 1 is for os and i/o addresses
	this is used if N !=0 and bits 31:32-N of VA are !=0.
	[31:14] physical address of first level translation table
	[13:5] SBZ
	[4:3] RGN b11 = Write-back, No Allocate on Write.
	MRC p15, 0, <Rd>, c2, c0, 1    ; Read Translation Table Base Register 0
	MCR p15, 0, <Rd>, c2, c0, 1    ; Write Translation Table Base Register 0

	The control register
	default is all zero's
	[2:0] N Boundry size
		b000 = 16KB, reset value
		b001 = 8KB
		b010 = 4KB
		b011 = 2KB
		b100 = 1KB
		b101 = 512-byte
		b110 = 256-byte
		b111 = 128-byte.
	
	MRC p15, 0, <Rd>, c2, c0, 2    ; Read Translation Table Base Control Register
	MCR p15, 0, <Rd>, c2, c0, 2    ; Write Translation Table Base Control Register

	Domain control register
	16 2bit values
	The purpose of the fields D15-D0 in the register is
	to define the access permissions for each one of the 16 domains. These domains
	can be either sections, large pages or small pages of memory:
	b00 = No access, reset value. Any access generates a domain fault.
	b01 = Client. Accesses are checked against the access permission bits in the TLB entry.
	b10 = Reserved. Any access generates a domain fault.
	b11 = Manager. Accesses are not checked against the access permission bits in the TLB entry, so a 
	permission fault cannot be generated


	*/
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
