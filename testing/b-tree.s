/* Rough initial implimentation of a sort of balanced binary tree
 * (super rough !!!!)
 * to use as a task schedular based on very limited understanding
 * by far the hardest will be to add/remove and rebalance tree
 */

	.text
	.align 2
_pick_tree:
	/* pick_tree picks the key from the tree. Head always points to lowest
	 * value fruit (key) and is a leaf
	 */
	stmfd sp!, {r4 - r7, lr}
	ldr r12, =hb_cur_list		@ get the hb_list to pick from
	ldr r3, [r12]
	ldrd r6, r7, [r3]		@ get head, root
	ldrd r4, r5, [r6, $8] 		@ r4 = parent, r5 = pid 
	cmp r6, r7
	beq _sw
	mov r0, r4
	bl _reset_head
_q:
	mov r0, r5
	ldmfd sp!, {r4 -r7, pc}

_sw:
	bl _swap_btree
	b _q

_reset_head:
	/* input r0 = node from which to find new head in b-tree
	 * if there is or are children of higher 'fruit[s]' then a singal rotate left
	 * is performed on that branch
	 */
	stmfd sp!, {lr}
	ldr r1, =hb_cur_list		@ get the hb_list to pick from
	ldr r12, [r0, $4]		@ get value of > child
	ldr r2, [r1]
	mov r3, $0
	cmp r12, $0			@ test if any > children
	str r3, [r0]			@ null < branch
	str r0, [r2, $4]		@ save new head
	blne _rotate_head		@ if r1(child)!=0 ; need to rotate left
	ldmfd sp!, {pc}
	
_rotate_head:
	/* r0 = pivot point
	 * As head should always be the lowest key then only a left rotate is
	 * needed, and branches rearanged to relocate head to lowest leaf
	 */
	.equ gtrchild, 4
	.equ parent, 8
	stmfd sp!, {r4 - r5}
	ldr r4, [r0, #gtrchild] 
	ldr r5, [r0, #parent]
	mov r3, $0
	str r3, [r0, #gtrchild]
	str r4, [r0, #parent]
	str r5, [r4, #parent]
	str r4, [r5]
	/* loop to find leaf to graft new leaf to */
	ldr r4, [r4]
_find_lsr_leaf:
	cmp r4, $0
	ldrne r4, [r4]
	bne _find_lsr_leaf 
	str r0, [r4]
	str r4, [r0]
	ldmfd sp!, {r4 - r5}
	bx lr

_swap_btree:
	/* swap <current> and <next> list round */
	ldr r12, =hb_cur_list
	ldrd r0, r1, [r12]
	str r0, [r12, $4]
	str r1, [r12]
	bx lr

_graft_new_fruit:
	/* insert new fruit (key) into b-tree. If graft is > than root then
	 * rotate left is performed to make <greater than child> of root the
	 * new root. Old_root becomes <lesser than child> of new_root
	 * The <lesser than branch> of the new_root is 'dettached' and
	 * and moved to become the new <greater than branch> of the old_root
	 * Input: R0 = Pid addr
	 *	  R1 = hb_list{x}
	 */
	stmfd sp!, {r4 - rx, lr}
	mov r4, r0
	mov r5, r1
	bl get_entry			@ get a mem loc on hb_list
	ldr r6, [r0, $4]		@ get PV
	ldr r3, [r1]			@ get root
	ldr r1, [r3, $16]		@ get key
	ldrd r2, r3, [r3]		@ get children
fl:					@ find leaf
	cmp r1, r6
	movmi r3, r2
	cmp r3, $0			@ leaf?
	ldrne r1, [r3, $16]		@ get key
	ldrdne r2, r3, [r3]		@ get children
	bne_fl
@@@ --- TODO
@@@ --- Create a address avalable in tree. A fifo queue
	


	.data
	.align 2

/* Process Table Entry */
P_entry:
	.word 0		@ PID  --process ID
	.word 0		@ PV   --priority val
	.word 0		@ PSTATE {1 - 7?}
		.rept 17	
	.word 0			@ PREG  --saved registers {r0 - r15, cprs}
		.endr
	.word 0
		.rept 32
	.asciz "\0"		@ PNAME --process name
		.endr

	.align 3	@ align 3 to allow ldrd/strd
hb_list0:
	.word 0		@ root
	.word 0		@ head
	/* fruits */
		.rept 20 @ Max number of process (can be changed later)
	.word 0		@ * < child addr 
	.word 0		@ * > child addr
	.word 0		@ parent addr
	.word 0		@ pid addr
	.word 0		@ KEY == PV
	.word 0		@ 
		.endr
hb_list1:
	.word 0		@ root
	.word 0		@ head
		.rept 20 @ Max number of process (can be changed later)
	.word 0		@ * < node
	.word 0		@ * > node
	.word 0		@ parent addr
	.word 0		@ pid addr
	.word 0		@ KEY == PV
	.word 0		@ 
		.endr

	.align 3	@ align 3 to allow ldrd/strd
hb_cur_list:		@ current process list to 'pick' from
	.word	hb_list0
hb_next_list:		@ next list to 'graft' in
	.word	hb_list1
