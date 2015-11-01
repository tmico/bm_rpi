/*Funtion to pass address of gpio in r0 */
/* The gpio controller base address starts at 0x20200000
 * There are 41 registers in total though some addresses are unused at
 * present, each 32 bits (1 word) wide 
 * There are in total 54 gpio pins {0 - 53}, each pin assigned 3 bits dealing
 * with input/ouput.(000 for input/ 001 for output) 
 * A register then can 'handle' 10 pins with the last 2 bits unused
 * So it requres 6 registers to deal with reading and writing to these pins
 *	register	offset	pins
 * 0	GPSEL0		#0	0-9
 * 1	GPSEL1		#4	10-19
 * 2	GPSEL2		#8	20-29
 * 3	GPSEL3		#12	30-39
 * 4	GPSEL4		#16	40-49
 * 5	GPSEL5		#20	50-53
 * 
 * Thus to 'talk' to pin 22 for example we need to address GPSEL2 which has
 * the address 0x20200000 + 8 and set bits 6-8 (counting from 0) to '000' for
 * input and '001' output. so effectivly bit 6 set to 1. eg 1 << 6
 * To not overwrite bits already set a bitwise operation is used.
 *	--note 3 bits allows for 8 functions in total (0-7) but values 2-7
 *	--are alternatives to 0-1
 * Once pin is configured for read/write then it needs to be set or clear - 
 * (on or off). --Note cmos  chips often use ntype transitors due to power
 * effency. things like led diods are often wired to light when pulling low
 * (off) rather than when pulling high. so to turn on an led you need to turn
 * it 'off'--. There are 4 registers dealing with setting and clearing pins
 *
 * No	register		offset	pins
 * 6 --not in use--
 * 7	GPOSET0		set	#28	0-31
 * 8	GPOSET1		set	#32	32-53
 * 9 --not in use--
 * 10	GPOCLR0		clear	#40	0-31
 * 11	GPOCLR1		clear	#44	32-53
 * 
 * So to set pin 22, bit 22 in GPOSET0 would need to be set at address
 * 0x20200000 + 28
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */


	.global _get_gpio_adr
_get_gpio_adr:				@ get address funtion
	ldr r3, =0x20200000
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
	ldr r3, =0x20200000		@ branching would waste 6 cycles
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
	ldreq r4, = 0x20200028		@ GPOCLR0 address
	ldrne r4, = 0x2020001c		@ GPOSET0 address
	cmp r0, #31			@ GPOxxx0 or GPOxxx1?
	subhi r0, r0, #32
	addhi r4, r4, #4		@ GPOxxx1 address if r0 > 31
	ldr r5, [r4]
	mov r1, #1
	mov r1, r1, lsl r0		@ set correct bit
	orr r0, r1, r5
	str r0, [r4]
	pop {r4-r6, pc}			@ return

