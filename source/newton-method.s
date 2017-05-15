
_udiv_32:
	/*Alternative to dived by shift and subtraction.
	 * This routine uses the newton-raphson method which has a better
	 * worst case performance. Not sure ill use it but it may be usefull to
	 * someone who (poor souls, God have mercy on them ) stumbles upon
	 * my code.
	 * The code below has been lifted straight from "Arm System Developer's
	 * Guide Designing and Optimizing System Software" section 7.3.2.1 pg 225
	*/
q .req r0	@ input denominater ; output quotent
r .req r1	@ input numerater	  ; output remainder
s .req r2	@ scratch
m .req r3	@ scratch
a .req r12	@ scratch
	
	ldr s, =t32
	ldr m, =b32
	clz s, q				@ find normalizing shifts
	movs a, q, lsl s			@ perform a lookup on the 
	add a, pc, a, lsr #25			@ most significant 7 bits
	/*ldrneb a, [a, #t32-b32-64]; from book*/@ of divisor ; **fails to compile**
	sub s, s, m
	sub s, s, #64
	ldrneb a, [a, s]
b32:
	subs s, s, $7				@ correct shift
	rsb m, q, $0				@ m = -d
	movpl q, a, lsl s			@ q approx (1<<32)/d
	/* 1st Newton iteration follows */
	mulpl a, q, m				@ a = -q*d
	bmi udiv_by_large_d
	smlawt q, q, a, q
	teq m, m, asr #1
	/* 2nd Newton iteration follows */
	mulne a, q, m
	movne s, $0
	smlalne s, q, a, q
	beq udiv_by_0_or_1
	/* q now accuret enough for a remainder r, 0<=r<3*d */
	umull s, q, r, q
	add r, r, m
	mla r, q, m, r
	/*since 0<= n-q*d < 3*d, thus -d <= r< 2*d */
	cmn r, m
	subcs r, r, m
	addcc q, q, $1
	addpl r, r, m, lsl $1
	addpl q, q, $32
	bx lr
udiv_by_large_d:
	/* At this point we know d >=2^(31-6)=2^25 */
	sub a, a, $4
	rsb s, s, $0
	mov q, a, lsr s
	umull s, q, r, q
	mla r, q, m, r
	/* q now accurate enough for a remainder r, 0<=r<4*d */
	cmn m, r, lsr $1
	addcs r, r, m, lsl $1
	addcs q, q, $2
	cmn m, r
	addcs r, r, m
	addcs q, q, $1
	bx lr
udiv_by_0_or_1:
	/* Carry set if d=1, carry clear if d=0 */
	movcs q, r
	movcs r, $0
	movcc q, $-1
	movcc r, $-1
	bx lr

.unreq q
.unreq r
.unreq s
.unreq m
.unreq a
	
	.data
	.align 2
	/* Table for 32 by 32 bit Newton Raphson divisions */
	@ table[0] = 256
	@ table[i] = (1<<14)/64+i) for i=1,2,3,...63
	
t32:
	.byte 0xff, 0xfc, 0xf8, 0xf4, 0xf0, 0xed, 0xea, 0xe6
	.byte 0xe3, 0xe0, 0xdd, 0xda, 0xd7, 0xd4, 0xd2, 0xcf
	.byte 0xcc, 0xca, 0xc7, 0xc5, 0xc3, 0xc0, 0xbe, 0xbc
	.byte 0xba, 0xb8, 0xb6, 0xb4, 0xb2, 0xb0, 0xae, 0xac
	.byte 0xaa, 0xa8, 0xa7, 0xa5, 0xa3, 0xa2, 0xa0, 0x9f
	.byte 0x9d, 0x9c, 0x9a, 0x99, 0x97, 0x96, 0x94, 0x93
	.byte 0x92, 0x90, 0x86, 0x8e, 0x8d, 0x8c, 0x8a, 0x89
	.byte 0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81
	
	
	
