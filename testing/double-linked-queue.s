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
	 *	 bp 	previous item
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
	.global _newqueue

	.equ HEAD,	8
	.equ TAIL,	12
/*
 * enqueue: Adds item to the tail of a doulbe linked list
 *	In:	r0 = &queue, r1 = &qent
 * 	Return: r0 = address on success -1 on failure
 */
 @-- tested ok 17-5-18
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
 @-- tested ok 17-5-18
	.type _getfirst	%function
	.type _dequeue	%function
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
 @-- tested ok 15-5-18
	.type _getlast	%function
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
 @-- tested ok 15-5-18
	.type _insert	%function
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
 @-- tested ok 14-5-18
	.type _newqueue	%function
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

@----- to delete -----
_get_loc:
	mov r12, $1
	str r12, [r0]
	bx lr
@---------------------
