	.global _enqueue
	.global _dequeue
	/* Double linked queue */
	/* qent consistes of double word. word0 = empty, word1 = key */
	/*
	 * queue structure: 8 byte align
	 *-----header---------
	 * mutex/lock
	 * head  word
	 * tail  word
	 *-----qent-----------
	 * fp
	 * bp
	 * Empty or item
	 * key
	 */

/* enqueue: Adds item to the tail of a doulbe linked list */
/* Input; r0 = &queue, r1 = &qent
 * Return: r0 = address on success -1 on failure
 */
_enqueue:
	stmfd sp!, {lr}
	bl _get_loc
	ldrd r2, r3, [r0, $4]		@ r2 = head, r3 = tail

	/* Is queue/list empty? If so adjust Head to --> this qent */
	add r12, r0, $8			@ r12 = &Tail
	cmp r2, r12			@ Head --> Tail then empty, then...
	ldrne r2, [r3]			@ ...ldr fp of last item if not...
	moveq r2, r1			@ ...set head --> to qent if empty...
	streq r2, [r0, $4]		@ ...and save it

	/* Append to queue */
	str r12, [r1]			@ new qent fp = &tail
	str r1, [r3]			@ reset tail to new qent
	str r2, [r1, $4]		@ bp of new_qent --> header/old_qent
	str r1, [r2]			@ fp of old_qent --> new_qent

	/* inc n.o items on list and save new entries */
	str r3, [r0, $8]
	b _exit

 _dequeue:
	stmfd sp!, {r4 - r6, lr}
	bl _get_loc
	ldr r4,[r0, $12]		@ r4 = size
	ldr r3, [r0, $8]		@ r2 = head, r3 = tail

	/* Is there an item on the list ? */
	cmp r4, $0			@ 0 == empty

