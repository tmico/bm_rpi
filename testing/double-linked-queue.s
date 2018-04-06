	/* Double linked queue
	 * qent consistes of double word. word0 = empty, word1 = key
	 *
	 * queue structure: 8 byte align
	 *	Tail is a pseudo qent, simplifying insertion
	 *-----header---------
	 * mutex/lock
	 * empty padding
	 * head  fp	1st qent
	 * tail  fp	TAIL+4	
	 *	 bp 	last item
	 *	 pseudo item
	 *	 pseudo key (signed int with value 0x8ffffffff)
	 *--------------------
	 *-----qent-----------
	 * fp -->
	 * bp <--
	 * Empty or item
	 * key
	 */

	.global _enqueue
	.global _dequeue
	.global _getfirst
	.global _getlast
	.global _insert

	.equ HEAD,	8
	.equ TAIL,	12
/*
 * enqueue: Adds item to the tail of a doulbe linked list
 *	In:	r0 = &queue, r1 = &qent
 * 	Return: r0 = address on success -1 on failure
 */
_enqueue:
	stmfd sp!, {lr}
	bl _get_loc
	ldr r3, [r0, $TAIL]		@ r3 = tail
	add r12, r0, $TAIL		@ r12 = &Tail

	/* Append to queue */
	str r12, [r1]			@ new qent fp = &tail
	ldr r2, [r3, $4]		@ ldr bp of TAIL
	str r1, [r3, $4]		@ reset tail to new qent
	str r2, [r1, $4]		@ bp of new_qent --> header/old_qent
	str r1, [r2]			@ fp of old_qent --> new_qent

	/* Exit */
	ldmfd sp!, {lr}
	mov r3, $0
	str r3, [r12, $-TAIL]		@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr

/*
 * deueue: removes item from head of list/queue
 *	In:	r0 = &queue
 *	Return: r0 &qent on success, -1 on failure
 */
_dequeue:
	stmfd sp!, {lr}
	bl _get_loc
	ldr r2, [r0, $HEAD]		@ r2 = head

	/* Is queue empty? If so, no qent to 'pop', return -1 */
	add r12, r0, $TAIL		@ r12 = &tail
	subne r3, r12, $4		@ r3 = &head
	cmp r2, r12			@ does head --> tail?
	ldrne r0, [r2]			@ r0 = &qent to pop
	moveq r0, $-1			@ will return -1 if empty
	ldrne r1, [r0]			@ r1 = next qent to be head of list
	strne r2, [r1, $4]		@ bp of next qent points to HEAD
	strne r1, [r12, $-4]		@ reset head to --> to next qent

	/* Exit */
	ldmfd sp!, {lr}
	mov r3, $0
	str r3, [r12, $-TAIL]		@ release lock
	mcr p15, 0, r3, c7, c10, 5	@ DMB
	bx lr

/*
 * getfirst: removes the first item (head) on a list
 *	In:	r0 = &queue
 *	Return: r0 = &qent on success, -1 on failure
 */
 _getfirst:
 	b _dequeue


/*
 * getlast: removes the last item (tail) on a list
 *	In:	r0 = &queue
 * 	Return: r0 = &qent on success, -1 on failure
 */
 _getlast:
	stmfd sp!, {lr}
	bl _get_loc
	ldr r2, [r0, $(TAIL+4)]		@ r2 = bp of tail

	/* Is queue empty? If so, no qent to 'pop', return -1 */
	add r12, r0, $HEAD		@ r12 = &HEAD
	add r3, r12, $8			@ r3 = &TAIL
	cmp r2, r12			@ does head <-- tail?
	ldrne r0, [r2]			@ r0 = &qent to pop
	moveq r0, $-1			@ queue empty ? r0 = -1
	ldrne r1, [r0, $4]		@ r1 = next qent to be tail of list
	strne r1, [r12, $4]		@ reset tail bp to --> to previous qent
	strne r3, [r1]			@ fp of next qent --> TAIL

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
	stmfd sp!, {r4 - r5, lr}
	bl _get_loc
	ldr r2, [r0, $HEAD]		@ r2 = fp of HEAD
	ldr r4, [r1, $12]		@ r4 = key of qent to insert
	ldr r3, [r2]			@ r3 = addr of 1st qent on list
	
	/* loop through list till find a higher key value  */
_1:	ldr r5, [r3, $12]		@ r5 = key of qent loaded
	mov r12, r2			@ preserve previous fp
	mov r2, r3
	cmp r4, r5			@ cmp the keys
	ldrlt r3, [r2]			@ r3 = next qent
	blt _1
	
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
