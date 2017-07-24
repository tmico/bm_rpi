/* Functions to operate on queues.
 *  squeue operates on singly linked queues
 *  dqueue operates on doubly linked queues
 *  fqueue operates on fifo circular buffer queue [Has to be multiples of 4bytes]
 *  strqueue operates on a string fifo
*/

	
	.global _fenqueue
_fenqueue:
	/* 
	 * Input r0 = fifo address to append data to
	 *	 r1 = int value
	 *
	 * structer of fifo queue:
	 *	.int lock
	 *	.int pointer to head
	 *	.int pointer to tail (points to nxt available slot
	 *	.int size (bytes) of buffer array. Must be multiple of 4
	 *	.byte x size buffer
	 */
	
	stmfd sp!, {r4, r5, lr}
	bl _get_loc

	ldr r4, [r0, $4]			@ get head
	ldr r5, [r0, $8]			@ get tail
	ldr r3, [r0, $12]			@ get size of buffer
	mov r12, r0				@ preserve a copy
	cmp r4, $0				@ if 0 then empty...
	bne _entail
_enhead:	
	str r1, [r0, $16]			@ ...set head and tail
	add r4, r0, $16				@ set head to point 1st entry
	add r5, r0, $20				@ set tail to point to end
	str r4, [r0, $4]
	str r5, [r0, $8]
	mov r0, $0
	b _exit

_entail:	
	cmp r4, r5				@ Is fifo full
	beq _queue_full
	str r1, [r5], $4			@ add to tail
	add r3, r3, $16
	add r3, r0, r3
	cmp r3, r5			      	@ r0 + 16 + r3 = max buffer addr
	addmi r5, r0, $16 			@ if overflow; reset
	str r5, [r0, $8]
	mov r0, $0				@ return 0 if successful
	moveq r0, $-1
	b _exit

	.global fdequeue
_fdequeue:
	/* Input: r0 = fifo addr (base struct to which fifo buffer belongs)
	 *
	 * Return: r0 addr of pointer
	 */
	stmfd sp!, {r4, r5, lr}
	bl _get_loc
	ldr r4, [r0, $4]			@ get head
	ldr r3, [r0, $12]			@ get size of buffer
	ldr r5, [r0, $8]			@ get tail
	mov r12, r0				@ preserve a copy

	ldr r0, [r4], $4
	add r3, r3, $16				@ r0 + 16 + r3 = Max buff addr
	add r3, r12, r3
	cmp r3, r4
	addmi r4, r12, $16			@ reset if overflow
	cmp r4, r5				@ if head = tail...
	moveq r4, $0				@ ...then buffer empty
	str r4, [r12, $4]			@ save new head
	b _exit

	
_get_loc:
	/* first in in struc holds mutex. 0 = free, 1 = lock. mutex at head of
	 * of struct to allow strex/ldrex to be used without having to adjust
	 * address in r0
	 */
	mov r12, $1				@ to set up a mutex on fifo
	ldrex r3, [r0]				@ get size and use as lock
	cmp r3, $0				@ valid size or locked?
	strexeq r2, r12, [r0]			@ lock if valid size there
	cmp r2, $0
	bxeq lr
	b _get_loc

_queue_full:	
	mov r0, $-1
	mov r1, $2
_exit:
	mov r3, $0
	str r3, [r12]				@ release lock
	mcr p15, 0, r3, c7, c10, 5		@ DMB
	ldmfd sp!, {r4, r5, pc}
