/* Number generator using  linear congruence generator.
	x[n+1] = ax[n] + b mod 2^32
 * Subject to the following constraints:

 1. a is even
 2. b = relatively prime
 3. mod is relatively prime			

 * r0 takes [i] the max value in the range of 0-[i]
===================================================*/
	.text
	.global _random_numgen
_random_numgen:
	ldr r3, =rand_a
	ldr r2, [r3]
	ldr r3, =rand_base
	ldr r1, [r3]
	mul r12, r1, r2
	mov r12, r12, ror $9
	add r12, r12, $0xb
	str r12, [r3]
	ldr r3, =rand_b 
	ldr r2, [r3]
	add r1, r12, r2
	/* need to make mask for [i] */
	clz r2, r0
	mov r1, r1, lsr r2
	cmp r1, r0			@ need number generated to fit range
	bcs _random_numgen
	mov r0, r1
	bx lr

	.data
.align 2
rand_a:
	.word 0x41c64e6d
rand_b:
	.word 12345
rand_base:
	.word 13
