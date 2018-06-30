/* Functions to operate on queues.
 *  squeue operates on singly linked queues
 *  dqueue operates on doubly linked queues
 *  fqueue operates on fifo circular buffer queue 
 *  strqueue operates on a string fifo
*/

	
	.global _fenqueue
_fenqueue:
	/* Input r0 = fifo address to append data to
	 *	 r1 = int value
	 *
	 * structer of fifo queue:
	 *	.int lock
	 *	.int pointer to head
	 *	.int pointer to tail (points to nxt available slot
	 *	.int fifo size (bytes) of buffer array. 
	 *	.int size buffer
	 */
	
	stmfd sp!, {r4 - r6, lr}
	bl _get_loc

	add r12, r0, $4				@ preserve base, inc to head
	ldr r4, [r12], $4			@ get head
	ldr r5, [r12], $4			@ get tail
	ldr r3, [r12], $4			@ get size of buffer
	cmp r4, r5				@ Is fifo full
	beq _queue_full
	cmp r4, $0				@ is fifo empty...
	moveq r4, r12				@ ...set head and tail
	moveq r5, r12

_fentail:	
	str r1, [r5], $4			@ add to tail
	add r3, r3, r12				@ r3 - 4  = max buffer addr
	cmp r3, r5
	moveq r5, r12	 			@ if overflow; reset
	str r5, [r0, $8]
	mov r0, $0
	b _exit


	.global _fdequeue
_fdequeue:
	/* Input: r0 = fifo addr (base struct to which fifo buffer belongs)
	 *
	 * Return: r0 addr of pointer
	 */
	stmfd sp!, {r4 - r6, lr}
	bl _get_loc
	add r12, r0, $4				@ preserve base, inc to head
	ldr r4, [r12], $4			@ get head
	ldr r5, [r12], $4			@ get tail
	ldr r3, [r12], $4			@ get size of buffer

	ldr r0, [r4], $4
	add r3, r12, r3				@ r3 - 4 = max buff addr
	cmp r3, r4
	moveq r4, r12				@ reset if overflow
	cmp r4, r5				@ if head = tail...
	moveq r4, $0				@ ...then buffer empty
	str r4, [r12, $-12]			@ save new head
	b _exit

	
	.global _get_loc
_get_loc:
	/* first in in struc holds mutex. 0 = free, 1 = lock. mutex at head of
	 * of struct to allow strex/ldrex to be used without having to adjust
	 * address in r0
	 */
	mov r12, $1				@ to set up a mutex on fifo
	ldrex r3, [r0]				@ get size and use as lock
	cmp r3, $0				@ valid size or locked?
	strexeq r3, r12, [r0]			@ lock if valid size there
	cmpeq r3, $0
	bxeq lr
	b _get_loc

_queue_full:	
	mov r0, $-1
	mov r1, $2
_exit:
	mov r3, $0
	str r3, [r12, $-16]			@ release lock
	mcr p15, 0, r3, c7, c10, 5		@ DMB
	ldmfd sp!, {r4 - r6, pc}


_strqueue:
	/* Input r0 = fifo address to append data to
	 *	 r1 = char array
	 *	 r2 = n.o char's
	 *
	 * Stucture of fifo buffer queue:
	 *	.int lock
	 *	.int pointer to head
	 *	.int pointer to tail
	 *	.int size (bytes)
	 *	.byte x size buffer (that is the fifo)
	 */
	stmfd sp!, {r4 - r6, lr}
	bl _get_loc

	add r12, r0, $4				@ preserve r0 and inc to head
	ldr r4, [r12], $4			@ get head and tail and size
	ldr r5, [r12], $4
	ldr r3, [r12], $4			@ ...r12 now points at start of fifo
	cmp r4, r5				@ is buffer full
	beq _queue_full
	cmp r4, $0				@ is buffer empty?
	moveq r4, r12
	moveq r5, r12				@ if so set head and tail

	/* while ((r2 != 0) && (r5 != r4)) copy string to fifo */
	ldrb r6, [r1], $1
	add r3, r3, r12				@ r3 - 1 = upper limit of buffer
_strmv:
	strb r6, [r5], $1
	cmp r5, r3				@ if r5 = max addr then...
	moveq r5, r12				@ ...loop to start
	subs r2, r2, $1
	cmpne r4, r5
	ldrneb r6, [r1], $1
	bne _strmv
	
	sub r5, r5, $1		
	str r5, [r0, $8]			@ save new tail
	mov r0, $0				@ return value
	b _exit

