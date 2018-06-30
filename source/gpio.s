.include "../include/sys.S"

	.global _get_gpio_adr
_get_gpio_adr:				@ get address funtion
	ldr r3, =GPIOBASE
	bx lr


/*_set_gpio_func - function to set the gpio pin(0-53) to read/write
 *			it takes the pin no in r0 and r1 is set to 0
 *			for read and 1 for write as arguments passed */

	.global _set_gpio_func
_set_gpio_func:
	cmp r0, #53			@ r0 holds pin no
	cmpls r1, #1			@ r1 hold 3bit funtion 0-1
	bxhi lr
	push {r4-r5, lr}
	mov r4, #7			@ a mask set even if r1 is 0 so that
					@ we can << to correct loction to clear
	ldr r3, =GPIOBASE
_funtionLoop$:				@ to get correct address
	cmp r0, #9			@ div by 10 using sub. the quotient
	subhi r0, r0, #10		@ holds the GPSEL of the pin we want
	addhi r3, r3, #4		@ which when *3 = bit to set in GPSEL
	bhi _funtionLoop$ 

	add r2, r0, r0, lsl #1		@ r0 * 3 to get correct bit
	cmp r1, #1			@ if r1 is 0 then read not write
	movne r1, #1
	mov r1, r1, lsl r2		@ mov funtion to correct bit
	mov r4, r4, lsl r2


/* need to str r1 to r3 without clearing bits set of other pins. Note that 
 * even though its only the least significant bit that matters per pin, another 
 * progam may have set the other bits too. If so these bits need to be cleared
 * using #7 left shifted in r4 */

	ldr r5, [r3]			@ get a copy
	bic r5, r5, r4			@ clear bit and set to read
	orreq r5, r5, r1		@ 'insert' write bit
	str r5, [r3]
	pop {r4-r5, pc}			@ return


/* _set_gpio - a funtion that either sets the gpio pin to on in GPOSET or
 *		sets pin to off in GPOCLR.
 *		it takes as its arguments in r0 the pin number and r1 holds an
 *		interger, 0 for 'off' and a non zero for 'on' */

	.global _set_gpio
_set_gpio:
	cmp r0, #53			@ is it a valid pin
	bxhi lr
	push {r4-r6, lr}
	cmp r1, #0			@ GPOSET or GPOCLR? 
	ldreq r4, = GPIOCLR0		@ GPOCLR0 address
	ldrne r4, = GPIOSET0		@ GPOSET0 address
	cmp r0, #31			@ GPOxxx0 or GPOxxx1?
	subhi r0, r0, #32
	addhi r4, r4, #4		@ GPOxxx1 address if r0 > 31
	ldr r5, [r4]
	mov r1, #1
	mov r1, r1, lsl r0		@ set correct bit
	orr r0, r1, r5
	str r0, [r4]
	pop {r4-r6, pc}			@ return

