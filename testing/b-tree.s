/* Rough initial implimentation of a red-black tree
 * (super rough !!!!)
 * to use as a task schedular based on very limited understanding
 * by far the hardest will be to add/remove and rebalance tree
 */

	.text
	.align 2
_pick_tree:
	/* pick_tree picks the key from the tree. Head always points to lowest
	 * value fruit (key)
	 */
	stmfd sp!, {r4 - r11}
	ldr r12, =hb_cur_list		@ get the hb_list to pick from
	ldr r3, [r12]
	ldrd r0, r1, [r3]		@ get head, root
	ldrd r4, r5, [r0, $8] 		@ r4 = parent, r5 = pid 
	

	.data
	.align 2

/* Process Table Entry */
P_entry:
	.word 0		@ PID  --process ID
	.word 0		@ PV   --priority val
	.word 0		@ PSTATE {1 - 7?}
		.rept 17	
	.word 0			@ PREG  --saved registers {r0 - r16, cprs}
		.endr
	.word 0
		.rept 32
	.asciz "\0"		@ PNAME --process name
		.endr

hb_cur_list:		@ current process list to 'pick' from
	.word	hb_list0
hb_next_list:		@ next list to 'graft' in
	.word	hb_list1

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
	.word 0		@ pid addr
	.word 0		@ KEY == PV
		.endr
