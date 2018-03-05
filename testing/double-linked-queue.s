	/* Double linked queue */
	/* qent consistes of double word. word0 = empty, word1 = key */
	/*
	 * queue structure: 8 byte align
	 *-----header---------
	 * mutex/lock
	 * head  word
	 * tail  word
	 * size (no of items)
	 *-----body-----------
	 * fp
	 * Empty or item
	 * key
	 * bp
	 */

/* enqueue: Adds item to the tail of a doulbe linked circular list */
/* Input; r0 = queue, r[1,2] = qent
 * Return: r0 = address on success -1 on failure
 */
_enqueue:
	stmfd sp!, {r4 - r6, lr}
	bl _get_loc
	ldr r3, [r0, $4]		@ r3 = head
	ldrd r4, r5, [r0, $8]		@ r4 = tail, r5 = size
	add r12, r0, $12		@ r12 = start of queue array
	add r5, r12, r5, lsl $2		@ r5 = end of queue

	/* Is queue full? */
	cmp r4, r3			@ Tail == head (full)
	beq _queue_full

	/* Is queue empty? */
	cmp r3, $0
	moveq r3, r12			@ set header to start if empty...
	moveq r4, r3			@ ...and tail
	
	/* Append to queue */
	str r1, [r4, $4]		@ str Item
	str r2, [r4, $8]		@ str key


