.include "../include/sys.S"

	.global _mailbox_write
_mailbox_write:
	ldr r3, =MAILBASE

	tst r0, #15				@ tst = (AND -> cmp 0)
	bxne lr					@ This block tests if values
	cmp r1, #15				@  in r0 r1 are valid
	bxhi lr					@ exit if values ! valid

	orr r0, r0, r1				@ combine data and channel
_chkStatusWrite$:				@ 1=full 0=empty
	ldr r2, [r3, #0x18]			@ status reg content
	tst r2, #0x80000000			@ tst bit 31
	bne  _chkStatusWrite$			@ if 1 branch till bit 31=0

	str r0, [r3, #0x20]			@ send to MB
	bx lr					@ exit

	.global _mailbox_read
_mailbox_read:
	ldr r3, =MAILREAD			@ base address
	cmp r0, #15				@ check valid channel
	bxhi lr

_chkStatusRead$:				@ 1=full 0=empty
	ldr r2, [r3, #0x18]			@ status reg content
	tst r2, #0x40000000
	bne _chkStatusRead$			@ if 1 branch till bit 30=0
_retrieve$:
	ldr r1, [r3]
	and r2, r1, #15
	teq r0, r2
	andeq r0, r1, #0xfffffff0
	bxeq lr
	b _chkStatusRead$  

