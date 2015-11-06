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

	[0-14]_STRIDE		31:16	D_Stride 2D mode byte increment at end of each row (YLength
				15:0	S_Stride 2D mode byte increcment of Source

	[0-14]_NEXTCNBK		31:0	Addr of next CB. Stop if 0x00000000
******************************************************************************/
	.text

	.data
	.align 5
	.global ConBlk_1
ConBlk_1:
	.word	0x00	@ TI
	.word	0x00	@ SOURCE_AD
	.word	0x00	@ DEST_AD
	.word	0x00	@ TXFR_LEN
	.word	0x00	@ STRIDE
	.word	0x00	@ NEXTCNBK
	.word	0x00	@ Reserved
	.word	0x00	@ Reserved

