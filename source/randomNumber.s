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
	ldr r1, =rand_a
	ldrd r2, r3, [r1]
	mla r12, r2, r3, r2
	str r12, [r1, $0x04]
	umull r1, r2, r12, r0
	mov r0, r2
	bx lr

	.data
.align 2
rand_a:					
	.word 0x41c64e6d		@ multiplier
	.word 13			@ seed

