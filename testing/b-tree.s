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
	 */
	stmfd sp!, {r4 - r7, lr}
	ldr r12, =hb_cur_list		@ get the hb_list to pick from
	ldr r3, [r12]
	ldrd r6, r7, [r3]		@ get head, root
	ldrd r4, r5, [r6, $8] 		@ r4 = parent, r5 = pid 
	cmp r6, r7			@ head == root?
	beq _sw
	mov r0, r4
	bl _reset_head
_q:
	mov r0, r5
	ldmfd sp!, {r4 -r7, pc}

_sw:
	mov r0, $0
	mov r1, r0
	strd r0, r1, [r3]		@ zero out head and tail
	bl _swap_btree
	b _q

_reset_head:
	/* input r0 = node from which to find new head in b-tree
	 * if there is or are children of higher 'fruit[s]' then a single rotate left
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
	 * Input: R0 = Pid addr
	 *	  R1 = hb_list{x}
	 */
	stmfd sp!, {r4 - r6, lr}
	ldr r3, [r1]			@ get root
	mov r4, r0
	mov r5, r1
	cmp r3, $0			@ fresh hb_list?
	beq _init_root
	ldr r6, [r0, $4]		@ get PV
	ldr r1, [r3, $16]		@ get roots key
	ldrd r2, r3, [r3]		@ get children
	mov r12, r1			@ copy roots key to cmp later
fl:					@ find leaf
	cmp r1, r6
	mov r0, r2			@ keep copy as future parent
	movmi r3, r2
	mov r0, r3			@ keep copy as future parent
	cmp r3, $0			@ leaf?
	ldrne r1, [r0, $16]		@ get key
	ldrned r2, r3, [r0]		@ get children
	bne _fl
_graft:	
	/* r0 parent, load r2 P_entry's (PID) hbslb addr, r4 PID's addr */
	ldr r2, [r4, $12]		@ get P_entry's alloted hbslb slot
	str r2, [r3]			@ str hbslb addr into branch
	str r0, [r2, $8]		@ set parent of P_entry slot
g1:	
	mov r3, $0
	str r3, [r2]			@ zero out children
	str r3, [r2, $4]
	
_balance_tree:
	/*if PID PV greater than root PV then rotate left*/
	cmp r12, r6			@ r12 == root_key, r6 == graft_key
	bpl _exit_graft

	ldr r3, [r5]			@ ldr root from (r5 == hb_list{x})
	ldr r1 [r3, $4]			@ ldr root > child
	mov r2, $0
	/*r1 will be new root, r3 lesser child to root.*/
	ldr r0, [r1]			@ r0 == r1 < child, will become r3 > child
	str r3, [r1]			@ r3 bcomes r1 < child
	str r1, [r3, $8]		@ r1 becomes r3 parent
	str r0, [r3, $4]		@ r0 becomes r3 > child
	str r1, [r5]			@ r1 becomes new root
	str r2, [r1, $12]		@ root's parent zero'd out 

_exit_graft:
	ldmfd sp!, {r4 - r6, lr}

_init_root:
	/* If hb_list is 'fresh' then first new p_entry grafted will
	 * be root and head
	 */
	ldr r2, [r4, $12]		@ get hbslb alloted slot
	str r2, [r5]			@ set root
	str r2, [r5, $4]		@ set head (remember its a fresh list)
	b gl				@ gl zero's children

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
	.word 0		@ pid addr
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
