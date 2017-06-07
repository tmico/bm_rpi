/*--- Tacken from BCM 2835 Arm peripherals documentation --- 
 *The BCM2835 DMA Controller provides a total of 16 DMA channels. Each channel operates
 * independently from the others and is internally arbitrated onto one of the 3 system busses.
 * This means that the amount of bandwidth that a DMA channel may consume can be
 * controlled by the arbiter settings.
 * Each DMA channel operates by loading a Control Block (CB) data structure from memory
 * into internal registers. The Control Block defines the required DMA operation. Each Control
 * Block can point to a further Control Block to be loaded and executed once the operation
 * described in the current Control Block has completed. In this way a linked list of Control
 * Blocks can be constructed in order to execute a sequence of DMA operations without
 * software intervention.
 *
 * Control Blocks (CB) are 8 words (256 bits) in length and must start at a 
 * 256-bit aligned address. The format of the CB data structure in memory, is shown 
 * below.
 * Each 32 bit word of the control block is automatically loaded into the 
 * corresponding 32 bit DMA control block register at the start of a DMA transfer. 
 * The descriptions of these registers also defines the corresponding bit locations 
 * in the CB data structure in memory.
 *
 *	32 bit word offset	Descripion		Associated RO register
 *	0			Tranfer information	TI
 *	1			Source addr		SOURCE_AD
 *	2			Destination addr	DEST_AD
 *	3			Tranfer length		TXFR_LEN
 *	4			2D mode stride		STRIDE
 *	5			Next control block	NEXTCNBK
 *	6,7			Reseved set to zero
 *
 * The DMA is started by writing the address of a CB structure into the 
 * CONBLK_AD register and then setting the ACTIVE bit. The DMA will fetch the CB 
 * from the address set in the SCB_ADDR field of this reg and it will load it into
 * the read-only registers described below. It will then begin a DMA transfer
 * according to the information in the CB. When it has completed the current DMA
 * transfer (length => 0) the DMA will update the CONBLK_AD register with the
 * contents of the NEXTCONBK register, fetch a new CB from that address, and
 * start the whole procedure once again. The DMA will stop (and clear the ACTIVE
 * bit) when it has completed a DMA transfer and the NEXTCONBK register is set to
 * 0x0000_0000. It will load this value into the CONBLK_AD reg and then stop. 
 * A few things to note:
 * As well as the Associated RO registers above (1 per dma chanel) there are
 * 2 more that need setting up.
 *	[0-15]_CS register: enable bit 2	interupt
 *			    enable bit 0	Active bit	 
 *	[0-15]_CONBLK_ADD 31:0		address of CB in mem. 256bit aligned

	++ Control Block Structure ++
 *	[0-6]_TI
			31:27	Reserved
			26	NO_WIDE_BURSTS
			25:21	WAITS
			16:20	PERMAP
			15:12	BUST_LENGTH
			11	SRC_IGNORE
			10	SRC_DREQ
			9	SRC_WIDTH	1=128, 0=32
			8	SRC_INC		address increment
			7	DEST_IGNORE
			6	DEST_DREQ
			5	DEST_WIDTH	1=128, 0=32
			4	DEST_INC	destination address increment
			3	WAIT_RESP
			2	reserved
			1	TDMODE		1=2D, 0=linear
			0	INTEN

	[0-14]_SOURCE_AD
			31:0	DMA Source Address

	[0-14]_DEST_AD	31:	DMA Destination Address

	[0-14]_TXFR_LEN		31:30	Reserved
				29:16	YLength	- in 2D mode no of XLengths
				15:0	XLength - Transfer length in bytes

	[0-14]_STRIDE		31:16	D_Stride 2D mode byte increment of 
					Destination at end of each row (YLength
				15:0	S_Stride 2D mode byte increment of Source

	[0-14]_NEXTCNBK		31:0	Addr of next CB. Stop if 0x00000000
******************************************************************************/
	.text
	.global _clrscr_dma0
	/* For time being _clrscr_dma0 is going to tranfer a buffer from mem to 
	   the gpu. A memory to GPU transfer. SreenBuffer is a buffer of
	   1 row of pixels acrros the screen. In 24bit mode thats 3,840 (0xf00)
	   bytes. In this implimentation going to use 2D xlengths of 3,840 bytes
	   x 720 (n.o rows) ylengths to clear the screen 
	*/ 
_clrscr_dma0:
	/* DEST_AD */
	ldr r0, =ConBlk_0
	ldr r2, =FramebufferInfo
	ldr r3, [r2, #32]			@ r3 = GPU pointer

	str r3, [r0, #8]			@ put it in CB DEST_AD
	
	/* SOURCE_AD */
	ldr r1, =TermInfo
	ldr r2, [r1]				@ Get addr of Framebuffer
	str r2, [r0, #4]			@ put SB into SOURCE_AD

	/* TXFR_LEN */
	mov r3, $0x1400				@ XLength = #3840 bytes
						@  stride being signed requires
						@  i stay under 0x8000 
	mov r2, $0x02d00000			@ YLength = #720 loops (shifted)
	orr r1, r2, r3				@ put TXFR_LEN into CB
	str r1, [r0, #12]

	/* STRIDE */
	rsb r2, r3, $0x00			@ get two's compliment 
	mvn r3, $0x00				@ mask
	and r1, r2, r3, lsr #16			@ inc Src is ls16 bits
	str r1, [r0, #16]			@ dec src to start of SB

	/* CONBLK_ADD */
	ldr r1, =0x20007000			@ DMA channel 0 addr
	str r0, [r1, #4]			@ load CB

	/* TI */
	mov r2, $0x33
	mov r2, r2, lsl #4
	add r2, r2, $0x0a			@ set bits to 0x033a
	str r2, [r0]				@ put TI into CB

	/* CS */
	mov r3, $0x01				@ ACTIVATE
	str r3, [r1]

	bx lr

	.global _clrl_dma0
_clrl_dma0:
	/* A dma transfer to clear a line of text from gpu framebuffer
	 * Input: R0 = address of Control Block with desired values stored
	 * Output: N/A
	 */ 
	ldr r1, =0x20007000			@ DMA channel 0 addr
	str r0, [r1, #4]			@ Str the CB
	mov r2, $0x01
	str r2, [r0]				@ Activate dma

	bx lr

	
	.data
	.align 5

	.global CB_ClearLine
CB_ClearLine:			@ Control Block with some preset values
	.word	0x23a		@ TI
	.word	BlankLine	@ #4 SOURCE_AD
	.word	0x00		@ #8 DEST_AD (CurLine * 16)
	.word	0xa0a00		@ #12 TXFR_LEN 
	.word	0xa000000	@ #16 STRIDE 
	.word	0x00		@ #20 NEXTCNBK
	.word	0x00		@ #24 Reserved
	.word	0x00		@ #28 Reserved

	.global ConBlk_0
ConBlk_0:
	.word	0x00	@ TI
	.word	0x00	@ SOURCE_AD
	.word	0x00	@ DEST_AD
	.word	0x00	@ TXFR_LEN
	.word	0x00	@ STRIDE
	.word	0x00	@ NEXTCNBK
	.word	0x00	@ Reserved
	.word	0x00	@ Reserved

