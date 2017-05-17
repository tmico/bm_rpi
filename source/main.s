	.section .init				@ initialize this section first
_reloc_exeption_image:
	.word 0xe59ff018		@ = ldr pc, [pc, #24]
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
reset_h:
	.word _reset
undefined_h:
	.word _undefined
swi_h:
	.word _swi
pre_abort_h:
	.word _pre_abort
data_abort_h:
	.word _data_abort
reserved_h:
	.word _reserved
irq_h:
	.word _irq_interupt
fiq_h:
	.word _fiq_interupt

/* ========= End of section init ========= */

	.section .main

	.global _start
_start:
	b _main

	.global _main
_main:

	/* routine to move around the screen fabienne's pic*/
_L0:
	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - dimentions of pic
	rsb r6, r8, $0x500			@  to get range for x and y
	rsb r7, r9, $0x2b0			@ 720-32-height = range for y

_L1:
	mov r0, r7
	bl _random_numgen
	add r4, r0, $0x20
	mov r0, r6
	bl _random_numgen
	mov r1, r4

	bl _display_pic
	
/*****************************************************************************/
/************** Testing *** Code *****************/
@testing transfer speeds between dma & cpu
	@bl _test_speeds
@	nop
@ testing soft system reboot
	ldr r0, =RebootMsg
	bl _kprint
	mov r0, r1
	bl _uart_ctr
	b _reboot_system

@ Delay routine
_delay:
	mov r0, $0x4000
_d1:
	subs r0, r0, $1
	bne _d1
	sub lr, lr, $12  @ dirty hack to test stuff
	bx lr

	/* dma transfer to clear screen */
/*	
	ldr r5, =SysTimer
_1:
	ldr r12, [r5]
	cmp r12, $0x08
	bmi _1	
	bl _clrscr_dma0				@ clear screen
	eor r12, r12
	str r12, [r5]

	
	b _L1
*/
_Bloop:						
	b _Bloop	@ Catch all loop

	.global _error$
_error$:
	mov r0, $0x2a000			
	bl _set_arm_timer

	b _Bloop
hfs:
	.asciz "Graphics address: %x\n"

	.data
	.align 2
	.global SysTimer
SysTimer:
	.int 0x00
RebootMsg:
	.asciz "The Pi Zero is rebooting"
