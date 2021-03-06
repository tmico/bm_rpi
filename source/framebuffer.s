.include "../include/sys.S"
	
	.section .data
.global FramebufferInfo
.align 4
/* Default values used if none are specified as arguments. Note that
   only Width, Height, bit depth can be passed as arguments. Width and
   Height values will be used for virtual Width and Height  */
FramebufferInfo:
.int 1280		@ #0 Physical Width (for my monitor)
.int 720		@ #4 Physical Hieght
.int 1280		@ #8 eg Virtual Width
.int 720		@ #12 eg Virtual Hieght
.int 0			@ #16 GPU Pitch, GPU will fill it. no bytes per row
.int 24			@ #20 bit depth
.int 0			@ #24 X offsets (pixils to skip in top left corner)
.int 0			@ #28 Y
.int 0			@ #32 GPU Pointer
.int 0			@ #36 GPU Size

	.section .text
	.global _init_framebuffer
_init_framebuffer:
	/* Check values passed in arguments are valid. If value in R0 given
		is zero then use defaults above*/
	push {lr}
	teq r0, $0
	ldr r3, =FramebufferInfo
	blne _Bchk_value
	
	/* Adjust for GPU mem adr (0x40000000) and send to mailbox ch1*/
	add r0, r3, $GPUADDR
	mov r1, $1
	bl _mailbox_write

	/* Get GPU pointer or error from Mailbox ch1 */
	mov r0, $1
	bl _mailbox_read
	cmp r0, $0
	ldreq r0, =FramebufferInfo				@ return address if success
	movne r0, $0
	pop {pc}
_Bchk_value:
	cmp r0, $4096
	cmpls r1, $4096
	cmpls r2, $32
	movhi r0, $0
	ldmhifd sp!, {pc}
	/* Write to framebuffer (FramebufferInfo)*/
	@@ str r0, [r3]				@ uncomment to use
	@@ str r1, [r3, #4]
	str r0, [r3]
	str r1, [r3, #4]
	str r0, [r3, #8]			@ virtual
	str r1, [r3, #12]			@ virtual
	str r2, [r3, #20]			@ color bit value
	bx lr					@ return from checking
