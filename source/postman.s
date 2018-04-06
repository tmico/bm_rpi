/* Routines to access the gpu on the arm
 * Mailboxes are the primary means of comunication between the ARM cpu and
 * the VCU (video core unit) on the broadcom 2835 Soc, Which powers the PI
 * Each MB (Mailbox) is an 8-deep FIFO 32bit words which can be read/write
 * by the ARM and the VC.
 
/* In the following code, the mailbox will be used to ask the VC for an
 * address to write to the screen.
 * MailboxRead, reading one message from the mailbox channel in r0. and 
 * MailboxWrite, writing the mem address in the top 28 bits of r0 to the 
 * mailbox channel in r1. (The address is 32bit long but as the 4 lsb 4 are
 * used for the channel id the address needs to be word aligned to ensure the
 * 4 lsb are all 0. The channel id is added into those 4 bits. The VC splits
 * the 32 bit address into 28:4. see below.(Format for ...)
 * Upon a succseful negotiation the VC returns a pointer (address) within
 * the data held at the address that was sent.The pointer is at [adr, #32]
 * The mailbox has 7 mailbox channels for communication with the graphics 
 * processor, only the second of which is useful to us,as it is for negotiating 
 * the frame buffer.

/* The following table describe the operation of the mailbox channel for VC

/* Table 3.1 Mailbox Addresses
 *	Address		Size	Name		Description	Read / Write
	2000B880	4	Read		Receiving mail.	R
	2000B890	4	Poll		Polling.	R
	2000B894	4	Sender		Sen info.	R
	2000B898	4	Status		Information.	R
	2000B89C	4	Configuration	Settings.	RW
	2000B8A0	4	Write		Sending mail.	W

/* Format for mailbox read
	bits	use		description
	0:3	channel_id	channel number from which data originated 
	4:31	data		28bit data sent to CPU

/* Format for mailbox write
	bits	use		description
	0:3	channel_id	channel number to which data is sent
	4:31	data		28 bit data sent to destination

/* Format for mailbax status
	bits	use		description
	0:29			N/A
	30	mail_read	1 for empty, 0 for full
	31	mail_write	1 for full, 0 writable

/* In order to send a message to a particular mailbox:

	The sender waits until the Status field has a 0 in the top bit.
	The sender writes to Write such that the lowest 4 bits are the mailbox 
	to write to, and the upper 28 bits are the message to write.

/* In order to read a message:

	The receiver waits until the Status field has a 0 in the 30th bit.
	The receiver reads from Read.
	The receiver confirms the message is for the correct mailbox, 
							and tries again if not.
*/
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

