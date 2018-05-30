/*
 * Rough initial implimentation of a sort of balanced binary tree
 * (super rough !!!!)
 * to use as a task schedular based on very limited understanding
 * by far the hardest will be to add/remove and rebalance tree
 */

	.global _pick_tree
	.global _graft_new_fruit
	.global _getpid
	.global _create_p	@-- TODO
	.global _destroy_p	@-- TODO
	.text
	.align 2
@------------------------------------------------
_pick_tree:
	/* pick_tree picks the key from the tree. Head always points to lowest
	 * value fruit (key) and is a leaf
	 * Out: r0 = pid (&P_entry)
	 */
	stmfd sp!, {r4 - r7}
	ldr r12, =hb_cur_list		@ get the hb_list to pick from
	ldr r3, [r12]
	mov r0, $0
	mov r1, $0
	ldrd r6, r7, [r3]		@ get root, head
	ldrd r4, r5, [r7, $8]

_reset_head:
	/* reset head by finding new lowest hb_entry.
	 * r3 = &hb_list
	 * r4 = parent of hb_entry being popped (old head)
	 * r7 = hb_entry being popped (old head)
	 */
	ldr r2, [r6, $4]		@ r2 = root > child to check empty tree?
	ldr r0, [r7, $4]		@ r0 = grtr child
	cmp r2, $0			@ if root > == 0 and...
	cmpeq r6, r7			@ ...head == tail then tree now empty
	beq _sw
	cmp r0, $0			@ if no grtr child ...
	str r0, [r4]			@   (if nz then link child to new...
	strne r4, [r0, $8]		@   ...parent)
	moveq r0, r4			@ ...get new head from parent instead
	ldr r2, [r0]			@ r2 = < child
_fh:
	cmp r2, $0
	movne r0, r2
	ldrne r2, [r0]
	bne _fh
	str r0, [r3, $4]		@ reset HEAD
_q:
	mov r0, r5
	ldmfd sp!, {r4 - r7}
	bx lr
	
_sw:
	strd r0, r1, [r3]		@ zero out head and tail
	mov r7, lr
	bl _swap_btree
	mov lr, r7
	b _q

@------------------------------------------------
_swap_btree:
	/* swap <current> and <next> list round */
	ldr r12, =hb_cur_list
	ldrd r0, r1, [r12]
	str r0, [r12, $4]
	str r1, [r12]
	bx lr

@------------------------------------------------
_graft_new_fruit:
	/* insert new fruit (key) into b-tree. If graft is > than root then
	 * rotate left is performed to make <greater than child> of root the
	 * new root. Old_root becomes <lesser than child> of new_root
	 * The <lesser than branch> of the new_root is 'dettached' and
	 * and moved to become the new <greater than branch> of the old_root
	 * Input: R0 = &P_entry
	 */
	stmfd sp!, {r4 - r6, lr}
	ldr r3, =hb_cur_list
	ldr r1, [r3]
	ldr r3, [r1]			@ get root
	ldr r6, [r0, $4]		@ get P_entry PV
	mov r4, r0
	mov r5, r1
	cmp r3, $0			@ fresh hb_list?
	beq _init_root
	ldr r1, [r3, $16]		@ get roots key
	mov r0, r3			@ copy to preserve
	ldrd r2, r3, [r0]		@ get children
	mov r12, r1			@ copy roots key to cmp later
fl:					@ find leaf
	cmp r6, r1			@ cmp the PV's
	movmi r3, r2
	cmp r3, $0			@ leaf?
	movne r0, r3			@ keep copy as future parent
	ldrne r1, [r0, $16]		@ get key
	ldrned r2, r3, [r0]		@ get children
	bne fl
_graft:	
	/* r0 parent, load r2 P_entry's (PID) hbslb addr, r4 PID's addr */
	ldr r2, [r4, $12]		@ get P_entry's alloted hbslb slot
	ldr r4, [r5, $4]		@ get HEAD add to cmp PV with poss later
	cmp r6, r1			@ < or > branch?
	strmi r2, [r0]			@ str hbslb addr into branch
	strpl r2, [r0, $4]		@ str hbslb addr into branch
	str r6, [r2, $16]		@ str pv in hbslb->key
	str r0, [r2, $8]		@ set parent of P_entry slot
g1:	
	mov r3, $0
	str r3, [r2]			@ zero out children
	str r3, [r2, $4]
	
_balance_tree:
	/*if PID PV greater than root PV then rotate left*/
	cmp r12, r6			@ r12 == root_key, r6 == graft_key
	bpl _pre_exit

	ldr r3, [r5]			@ r3 = root hb
	ldr r1, [r3, $4]		@ r1 = roots > child
	mov r2, $0
	cmp r1, $0
	beq _exit_graft
	/*r1 will be new root, r3 lesser child to root.*/
	ldr r0, [r1]			@ r0 == r1 < child, will become r3 > child
	str r3, [r1]			@ r3 bcomes r1 < child
	str r1, [r3, $8]		@ r1 becomes r3 parent
	str r0, [r3, $4]		@ r0 becomes r3 > child
	str r1, [r5]			@ r1 becomes new root
	str r2, [r1, $8]		@ root's parent zero'd out 

_exit_graft:
	ldmfd sp!, {r4 - r6, pc}

_pre_exit:
	/* cmp P_entry.PV with HEAD.PV and reset HEAD if 
	 * P_entry.PV < HEAD.PV
	 */
	ldr r3, [r4, $16]		@ get HEAD.PV
	cmp r6, r3
	strmi r2, [r5, $4]		@ if < reset head
	b _exit_graft

_init_root:
	/* If hb_list is 'fresh' then first new p_entry grafted will
	 * be root and head
	 */
	ldr r2, [r4, $12]		@ get hbslb alloted slot
	str r2, [r5]			@ set root
	str r2, [r5, $4]		@ set head (remember its a fresh list)

	str r3, [r2]			@ zero out children
	str r3, [r2, $4]
	str r3, [r2, $8]
	str r6, [r2, $16]		@ str pv in hbslb->key
	b _exit_graft			@ gl zero's children

@------------------------------------------------
_getpid:
	/* returns the pid of current process */
	ldr r3, =CURPID
	ldr r2, [r3]
	ldr r0, [r2]
	bx lr


@------------------------------------------------
	.data
	.align 2

/* CURPID: Current pid address */
CURPID:
	.word 0		@ addr of cur pid

/* Process Table Entry */
P_entry:
	.word 0		@ PID  --process ID
	.word 0		@ PV   --priority val
	.word 0		@ PSTATE {1 - 7?}
	.word 0		@ hb_addr (Addr of 24 bytes slot to put on hbslb
		.rept 17	
	.word 0		@ PREG  --saved registers {r0 - r15, cprs}
		.endr
	.word 0
		.rept 32
	.asciz "\0"	@ PNAME --process name
		.endr

	.align 3	@ align 3 to allow ldrd/strd
	
/* P_entry linked hb_list tree */
hbslb:			@ hb_shared_linked_basket */
		.rept 50
	.word 0		@ * < child addr 
	.word 0		@ * > child addr
	.word 0		@ parent addr
	.word 0		@ pid addr (&P_entry)
	.word 0		@ KEY == PV
	.word 0		@ 
		.endr
hb_list0:
	.word 0		@ root
	.word 0		@ head

hb_list1:
	.word 0		@ root
	.word 0		@ head

	.align 3	@ align 3 to allow ldrd/strd
hb_cur_list:		@ current process list to 'pick' from
	.word	hb_list0
hb_next_list:		@ next list to 'graft' in
	.word	hb_list1
