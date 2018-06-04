/*
 * Rough initial implimentation of a sort of balanced binary tree
 * (super rough !!!!)
 * to use as a task schedular based on very limited understanding
 * by far the hardest will be to add/remove and rebalance tree
 */
/*
 * ------- Process Table Entry struct -------
 *P_entry:
 *        .word 0		@ PID  --process ID
 *        .word 0		@ PV   --priority val
 *        .word 0		@ PSTATE {1 - 7?}
 *        .word 0		@ hb_addr (Addr of 24 bytes slot to put on hbslb
 *                .rept 17	
 *        .word 0		@ PREG  --saved registers {r0 - r15, cprs}
 *                .endr
 *        .word 0
 *                .rept 32
 *        .asciz "\0"	@ PNAME --process name
 *                .endr
 *
 *        .align 3	@ align 3 to allow ldrd/strd
 *        
 * ------- P_entry linked hb_list tree struct --------
 *hbslb:			@ hb_shared_linked_basket 
 *        .word 0		@ * < child addr 
 *        .word 0		@ * > child addr
 *        .word 0		@ parent addr
 *        .word 0		@ pid addr (&P_entry)
 *        .word 0		@ KEY == PV
 *        .word 0		@ 
 *---------------------------------------------
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
	ldrd r6, r7, [r3]		@ get root, head
	ldr r12, [r3, $8]		@ r12 = < count
	ldrd r4, r5, [r7, $8]		@ r4 = parent, r5 = &pid

_reset_head:
	
	/* reset head by finding new lowest hb_entry.
	 * r3 = &hb_list
	 * r4 = parent of hb_entry being popped (old head)
	 * r6 = root from which to find new head
	 * r7 = hb_entry being popped (old head)
	 */
	ldr r0, [r7, $4]		@ r2 = r7's > child 
	sub r12, r12, $1
	cmp r7, r6			@ head == root? reset root or swap list
	beq _rotate

	cmp r0, $0			@ if no grtr child ...
	str r0, [r4]			@   (if nz then link child to its... 
	strne r4, [r0, $8]		@   ...new parent)
	moveq r0, r4			@ ...get new head from parent instead
	ldr r2, [r0]			@ r2 = < child
	str r12, [r3, $8]		@ adjust < count
_fh:
	cmp r2, $0
	movne r0, r2
	ldrne r2, [r0]
	bne _fh
	str r0, [r3, $4]		@ reset HEAD

	/* Exit */
_q:
	mov r0, r5
	ldmfd sp!, {r4 - r7}
	bx lr
	
_rotate:
	/* r0 = new root, r3 = hb_list */
	cmp r0, $0
	beq _sw
	ldr r1, [r0]			@ r1 = new head
	ldr r2, [r3, $12]		@ r2 = > count, r12 < counter
	str r0, [r3]			@ save new root
	mov r6, $0
	str r6, [r0, $8]		@ delete root parent
_h:
	cmp r1, $0			@ loop to find new head
	movne r0, r1
	ldrne r1, [r0]
	addne r12, r12, $1
	bne _h
	str r0, [r3, $4]		@ save new head
	sub r2, r2, $1
	str r2, [r3, $12]
	str r12, [r3, $8]		@ save counters

	b _q
	

@------------------------------------------------
_sw:
	/* swap <current> and <next> list round */
	ldr r12, =hb_cur_list
	mov r2, $0
	mov r3, $0
	ldrd r0, r1, [r12]
	strd r2, r3, [r1]
	str r0, [r12, $4]
	str r1, [r12]
	b _q

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
	mov r5, r1			@ r5 = hb_list
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
	strmi r2, [r0]			@ str hbslb addr into < branch
	strpl r2, [r0, $4]		@ str hbslb addr into > branch
	str r6, [r2, $16]		@ str pv in hbslb->key
	str r0, [r2, $8]		@ set parent of P_entry slot
g1:	
	mov r3, $0
	str r3, [r2]			@ zero out children
	str r3, [r2, $4]
	
_balance_tree:
	/*if PID PV greater than root PV then rotate left*/
	ldrd r0, r1, [r5, $8]		@ r0 = < count, r1 = > count
	cmp r12, r6			@ r12 == root_key, r6 == graft_key
	bpl _pre_exit

	subs r3, r0, r1			@ if diff >  then rotate
	add r1, r1, $1
	strpl r1, [r5, $12]		@ save > count
	bpl _exit_graft
	/* r1 will be new root, r3 lesser child to root and parent to r0,
	 * r0 changing to r3 greater child from r1
	 */
	ldr r3, [r5]			@ r3 = root hb
	add r0, r0, $1			@ due to rotate add 1 to < count
	ldr r1, [r3, $4]		@ r1 = roots > child
	mov r2, $0
	cmp r1, $0
	beq _exit_graft			@ if no > child then exit
	str r0, [r5, $8]		@ save < count
	ldr r0, [r1]			@ r0 == r1 < child, will become r3 > child
	str r3, [r1]			@ r3 bcomes r1 < child
	str r1, [r3, $8]		@ r1 becomes r3 parent
	str r0, [r3, $4]		@ r0 becomes r3 > child
	cmp r0, $0
	strne r3, [r0, $8]		@ r3 becomes r0 parent
	str r1, [r5]			@ r1 becomes new root
	str r2, [r1, $8]		@ root's parent zero'd out 

_exit_graft:
	ldmfd sp!, {r4 - r6, pc}

_pre_exit:
	/* cmp P_entry.PV with HEAD.PV and reset HEAD if 
	 * P_entry.PV < HEAD.PV
	 */
	ldr r3, [r4, $16]		@ get HEAD.PV
	add r0, r0, $1			@ increment < count
	str r0, [r5, $8]		@ save < count
	cmp r6, r3
	strmi r2, [r5, $4]		@ if < reset head
	b _exit_graft

_init_root:
	/* If hb_list is 'fresh' then first new p_entry grafted will
	 * be root and head
	 */
	ldr r2, [r4, $12]		@ get hbslb alloted slot
	mov r0, $0
	mov r1, $0
	strd r0, r1, [r5, $8]		@ zero < and > counter
	str r2, [r5]			@ set root
	str r2, [r5, $4]		@ set head (remember its a fresh list)

	strd r0, r1, [r2]		@ zero out children
	str r0, [r2, $8]
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


hb_list0:
	.word 0		@ root
	.word 0		@ head
	.word 0		@ < count
	.word 0		@ > count

hb_list1:
	.word 0		@ root
	.word 0		@ head
	.word 0		@ < count
	.word 0		@ > count

	.align 3	@ align 3 to allow ldrd/strd
hb_cur_list:		@ current process list to 'pick' from
	.word	hb_list0
hb_next_list:		@ next list to 'graft' in
	.word	hb_list1
