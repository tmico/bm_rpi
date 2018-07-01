/* Functions to operate on queues.
 *  squeue operates on singly linked queues
 *  fqueue operates on fifo circular buffer queue 
 *  strqueue operates on a string fifo
 *  enqueue add to tail of doubly linked list/queue
 *  dequeue removes from head of list/queue
 *  getfirst removes from head of list/queue
 *  getlast removes from tail of list/queue
 *  insert inserts in assending order of key
 *  newqueue creates a new doubly linked list/queue header
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


	/*==========================================================
	 * Double linked queue
	 * qent consistes of double word. word0 = empty, word1 = key
	 *
	 * queue structure: 8 byte align
	 *	Tail is a pseudo qent, simplifying insertion
	 *-----header---------
	 * mutex/lock
	 * empty padding
	 * head  fp	1st qent
	 * tail  fp	TAIL+4	
	 *	 bp 	previous item
	 *	 pseudo item
	 *	 pseudo key (signed int with value 0x8ffffffff)
	 *--------------------
	 *-----qent-----------
	 * fp -->
	 * bp <--
	 * Empty or item
	 * key
	 *=========================================================
	 */

	.equ HEAD,	8
	.equ TAIL,	12
	.global _enqueue
/*
 * enqueue: Adds item to the tail of a doulbe linked list
 *	In:	r0 = &queue, r1 = &qent
 * 	Return: r0 = address on success -1 on failure
 */
_enqueue:
	stmfd sp!, {lr}
	bl _get_loc
	add r12, r0, $TAIL		@ r12 = &Tail

	/* Append to queue */
	str r12, [r1]			@ new qent fp = &tail
	ldr r2, [r12, $4]		@ ldr bp of TAIL
	str r1, [r12, $4]		@ reset tail to new qent
	str r2, [r1, $4]		@ bp of new_qent --> header/old_qent
	str r1, [r2]			@ fp of old_qent --> new_qent

	/* Exit */
	ldmfd sp!, {lr}
	mov r3, $0
	str r3, [r12, $-TAIL]		@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr

/*
 * getfirst: alias for dequeue
 * dequeue: removes item from head of list/queue
 *	In:	r0 = &queue
 *	Return: r0 &qent on success, 0 on failure
 */
	.global _dequeue
	.global _getfirst
_dequeue:
_getfirst:
	stmfd sp!, {lr}
	bl _get_loc
	ldr r2, [r0, $HEAD]		@ r2 = head

	/* Is queue empty? If so, no qent to 'pop', return 0 */
	add r12, r0, $TAIL		@ r12 = &tail
	cmp r2, r12			@ does head --> tail?
	movne r0, r2			@ r0 = &qent to pop
	moveq r0, $0			@ will return 0 if empty
	ldrne r1, [r0]			@ r1 = next qent to be head of list
	sub r2, r12, $4			@ r2 = &head
	strne r2, [r1, $4]		@ bp of next qent points to HEAD
	strne r1, [r12, $-4]		@ reset head to --> to next qent

	/* Exit */
	ldmfd sp!, {lr}
	mov r3, $0
	str r3, [r12, $-TAIL]		@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr


/*
 * getlast: removes the last item (tail) on a list
 *	In:	r0 = &queue
 * 	Return: r0 = &qent on success, 0 on failure
 */
	.global _getlast
 _getlast:
	stmfd sp!, {lr}
	bl _get_loc
	ldr r3, [r0, $(TAIL+4)]		@ r2 = bp of tail

	/* Is queue empty? If so, no qent to 'pop', return 0 */
	add r12, r0, $HEAD		@ r12 = &HEAD
	cmp r3, r12			@ does head <-- tail?
	movne r0, r3			@ r0 = &qent to pop
	ldrne r1, [r0, $4]		@ r1 = next qent to be tail of list
	moveq r0, $0			@ queue empty ? r0 = 0
	add r2, r12, $4			@ r2 = &TAIL's bp
	strne r1, [r12, $8]		@ reset tail bp to --> to previous qent
	strne r2, [r1]			@ fp of next qent --> TAIL

	/* Exit */
	ldmfd sp!, {lr}
	mov r3, $0
	str r3, [r12, $-HEAD]		@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr

/*
 * Insert: insert qent in key (low to high) order on list
 *	In:	r0 = &queue/list,
 *		r1 = &qent
 * 	Return:	r0 = 0 on success, -1 of failure
 */
	.global _insert
_insert:
	stmfd sp!, {r4 - r5, lr}
	bl _get_loc
	add r2, r0, $HEAD		@ r2 = &(fp of HEAD)
	ldr r3, [r2]			@ r3 = addr of 1st qent on list
	ldr r4, [r1, $12]		@ r4 = key of qent to insert
	
	/* loop through list till find a higher key value  */
_1:	ldr r5, [r3, $12]		@ r5 = key of qent loaded
	mov r12, r2			@ preserve previous fp
	mov r2, r3
	cmp r4, r5			@ cmp the keys
	ldrhi r3, [r2]			@ r3 = next qent
	bhi _1
	
	str r1, [r12]			@ previous qent's fp
	str r1, [r3, $4]		@ current qent's bp
	str r3, [r1]			@ set new qent fp...
	str r12, [r1, $4]		@ ...and bp

	/* exit */			 
	ldmfd sp!, {r4 - r5, lr}
	mov r3, $0
	str r3, [r0]			@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr

/*
 * newqueue: Initialise a new queue
 *        In: r0 address of header for new queue/list
 *        Return: r0 = address of new queue on success, 0 on failure
 */
	.global _newqueue
_newqueue:
	mov r1, $1
	str r1, [r0]			@ create the lock
	add r1, r0, $12			@ r1 = &TAIL
	str r1, [r0, $HEAD]
	str r1, [r0, $TAIL]
	add r1, r0, $8			@ r1 = &HEAD
	str r1, [r0, $(TAIL+4)]
	mov r1, $0xffffffff		@ pseudo key = largest unsigned value
	str r1, [r0, $(TAIL+12)]
	mov r1, $0			@ unlock new list
	str r1, [r0]

	/* exit */
	bx lr
/*
 * get lock: Creates a lock on list/queue whilst an item is being
 * 	add/removed form it. getlock called directly by queue functions
 *	to lock the queues or lists they are operating on.
 *	A spin lock occurs until a successfull lock is obtained
 *	In: r0 &(list header). First word holds the mutex
 */
_get_loc:
	mov r12, $1				@ to set up a mutex on fifo
	ldrex r3, [r0]				@ get size and use as lock
	cmp r3, $0				@ valid size or locked?
	strexeq r3, r12, [r0]			@ lock if valid size there
	cmpeq r3, $0
	bxeq lr
	b _get_loc

