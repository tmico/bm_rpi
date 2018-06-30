	.include "../include/macro.S"
	.section .init				@ initialize this section first
	.global _start

_start:
	b _reset
@=============================================
@ End of section init 
@ Section main
@=============================================
	.section .main
	.global _main
_main:
	/* routine to on the screen fabienne's pic*/
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
	
@==============================================
@ Testing Code 
@==============================================

ex:	
	/* example of how to use exclusive locks */
	ldr r3, =TstLock
	mov r1, $1
	ldrex r2, [r3]
	cmp r2, $0				@ free?
	strexeq r2, r1, [r3]			@ Attempt to lock it
	cmpeq r2, $0				@ 0 = success, 1 = fail
	bne ex
	
	/* test syscall write (only prints to uart for time being) */
	ldr r0, =RandomMsg
	ldr r1, =RandomMsgLgth
	bl _puts
	ldr r0, =TstLock
	mov r1, $0
	str r1, [r0]				@ Attempt to free lock
	DMB
	
	ldr r1, =A
	mov r0, $1
	mov r7, $4
	svc 0

	nop
	/* === move 'Bloop' to where to bring to a close ===*/
	b _Bloop
	/* =================================================*/


_Bloop:						
	nop
	b _Bloop	@ Catch all loop

	.global _error$
_error$:
	mov r0, $0x2a000			
	bl _set_arm_timer

	b _Bloop

TstLock:
	.word 0


@==============================================
@ Random Data
@==============================================
	.data
	.align 2

RebootMsg:
	.asciz "The Pi Zero is rebooting"

RandomMsg:
	.asciz "Hello this is a random message.\nIf you can read this then it probably means it works (of sorts!)\n"
RandomMsgLgth =.-RandomMsg	

