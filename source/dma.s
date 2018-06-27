	.include "../include/sys.S"
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
	ldr r1, =DMA0				@ DMA channel 0 addr
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
	ldr r1, =DMA0				@ DMA channel 0 addr	
	str r0, [r1, #4]			@ Str the CB
	mov r2, $0x01
	str r2, [r0]				@ Activate dma

	bx lr

	
	.data
	.align 5

	/* The Control Block to do a dma transfer has some preset values but others
	   will need to be calculated at run time such as the gpu mem addr 
	   pointing to correct line to blank out. 
	   (TXFR = (hi hw = 16 (y)) (lo hw = 0xa00 (4 (bytes) * 8 (pixels) * 80 (char))
	   (d_stride = 0x1400 (1280 pixels) - 0xa00 (80 char), s_stride = 0)
	*/
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

