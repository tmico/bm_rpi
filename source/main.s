	.section .init				@ initialize this section first
	.global _start

_start:
	b _reset

/* ========= End of section init ========= */
	.section .main
	b _main

	.global _main
_main:

	/* routine to move around the screen fabienne's pic*/
_L0:
	ldr r10, = FabPic
	ldrd r8, r9, [r10, $0x10]		@ 0x10 - dimentions of pic ...
	rsb r6, r8, $0x500			@ ...to get range for x and y
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
@ testing stuff
ex:	
	ldr r0, =TstLock
	mov r1, $1
	ldrex r2, [r0]
	cmp r2, $0				@ free?
	strexeq r2, r1, [r0]			@ Attempt to lock it
	cmp r2, $0				@ 0 = success, 1 = fail
	bne ex
	svc 0
	ldr r0, =TstLock
	mov r1, $0
	str r1, [r0]				@ Attempt to free it
	b _Bloop
	
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
	nop
	b _Bloop	@ Catch all loop

	.global _error$
_error$:
	mov r0, $0x2a000			
	bl _set_arm_timer

	b _Bloop

	.data
	.align 2
RebootMsg:
	.asciz "The Pi Zero is rebooting"

TstLock:
	.int 0

	/* Old code not brought myself to delete yet as i may change my mind
	 * and want to use it
	 */

_reloc_exeption_image:
	.word 0xe59ff018		@ = ldr pc, [pc, #24]
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018
	.word 0xe59ff018

	.word _reset
	.word _undefined
	.word _swi
	.word _pre_abort
	.word _data_abort
	.word _reserved
	.word _irq_interupt
	.word _fiq_interupt
