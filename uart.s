	/* README to do */
	/* gpio pin 14: tx
	   gpio pin 15: rx
	/* Base address of registors
	GPIO_base 0x202000000
	GPIO_PUD (GPIO_BASE) + 0x94	from what i can make out the pull down
					resitor needs to be disabled.
	GPIO_PUDCLK0 (GPIO_BASE) + 0x98 Controls actuation of pull up/down of
					specific gpio pin.

     The base address for UART.
    UART0_BASE = 0x20201000,
 
    UART0_DR     = (UART0_BASE + 0x00),
    UART0_RSRECR = (UART0_BASE + 0x04),
    UART0_FR     = (UART0_BASE + 0x18),
    UART0_ILPR   = (UART0_BASE + 0x20),
    UART0_IBRD   = (UART0_BASE + 0x24),
    UART0_FBRD   = (UART0_BASE + 0x28),
    UART0_LCRH   = (UART0_BASE + 0x2C),
    UART0_CR     = (UART0_BASE + 0x30),
    UART0_IFLS   = (UART0_BASE + 0x34),
    UART0_IMSC   = (UART0_BASE + 0x38),
    UART0_RIS    = (UART0_BASE + 0x3C),
    UART0_MIS    = (UART0_BASE + 0x40),
    UART0_ICR    = (UART0_BASE + 0x44),
    UART0_DMACR  = (UART0_BASE + 0x48),
    UART0_ITCR   = (UART0_BASE + 0x80),
    UART0_ITIP   = (UART0_BASE + 0x84),
    UART0_ITOP   = (UART0_BASE + 0x88),
    UART0_TDR    = (UART0_BASE + 0x8C),
*/
	.global _uart_t
	.global _uart_r
	.global _rxtx_char

_uart_init:
	/* Entry point to this function is from uart_t. _uart_init is a once only
	   function to prepare (or reset) pins as i don't know what state u-boot
	   leaves them after exiting
	*/
	/* Note no checks are made to test whether uart communication is ongoing
	   or not!!
	*/
	mov r12, lr				@ copy to save pushing
	ldr r1, Uart0_Base
	ldr r2, Gpio_Base

	mov r3, $0x0
	str r3, [r1, $0x30]			@ disable uart0

	/* setup the gpio pins for uart the bcm2835 manual informs that uart
	   uses pins 14 (tx) and 15 (rx) in alternate function 0
	*/
	ldr r3, [r2, $4]			@ get current gpio funct
	bic r3, $((7<<12)|(7<<15))		@ (re)set pins funct to
	orr r3, $((4<<12)|(4<<15))		@  alt funct 0
	str r3, [r2, $4]

	/*Disable the pull up/downs */
	mov r3, $0
	str r3, [r2,$0x94]
	bl _delay				@ delay required
	mov r3, $((1<<14)|(1<<15))		@ gpio's to disable
	str r3, [r2, $0x98]			@ clock control signal to pads
	bl _delay
	mov r3, $0
	str r3, [r2, $0x98]			@ remove the clock

	/* Set baudrate to 115200 */
	/* Divider = 3000000 / (16 * 115200) = 1.627
	   Fractional part = (.627 * 64) + 0.5 = 40.6 = 40
	   (fraction calculation makes no sense to me, but tacken from
	   arm website)
	*/
	mov r3, $1
	str r3, [r1, $0x24]
	mov r3, $40
	str r3, [r1, $0x28]

	/* clear pending interupts and set interupt masks */
	mov r3, $0x7f0
	add r3, r3, $0x2
	str r3, [r1, $0x44]
	str r3, [r1, $0x38]


	/* flush fifo, reenable tx and rx */
	mov r2, $0
	str r2, [r1, $0x2c]			@ flush fifo

_ut2:
	ldr r2, [r1, $0x18]			@ get status from flag reg
	tst r2, $(1<<3)				@  and tst 'busy' bit
	bne _ut2				@ wait till not busy

	mov r2, $((1<<4)|(1<<5)|(1<<6))		@ enable fifo, 8 bit tx
	str r2, [r1, $0x2c]

	mov r2, $((1<<8)|(1<<9))		@ enable uart, tx, rx
	orr r2, r2, $1
	str r2, [r1, $0x30]

	/* store uart0 ready */
	ldr r3, =UartInit
	mov r2, $1
	str r2, [r3]

	bx r12					@ return 


	/* 150 cycle delay loop, GPIO_PUD and GPIO_PUDCLK0 both require a delay
	   150 cycles. The code bellow asumes branch prediction may be on (along
	   with btac and branch folding) so a constant of 150 is used, don't
	   think going over is a problem
	*/
_delay:
	mov r3, $150
_D1:
	subs r3, r3, $1
	bne _D1
	bx lr

_uart_t:
	/* To enable transmision, disable uart, wait for end of transmision,
	   flush fifo by seting fen bit to 0 in uart_lcrh, reprogram uart_cr,
	   enable uart.
	   swp instruction used to implement a mutex with UartLck 
	*/

	ldr r3, =UartLck
	mov r2, $1				@ 1 = in use, 0 free mutex
	swp r2, r2, [r3]			@ semaphore: atomic ldr and str
	cmp r2, $0				@ can we carry on?
	mvnne r0, $0				@ if not return -1
	bxne lr

	stmfd sp!, {lr}
	ldr r3, =UartInit
	ldr r1, [r3]
	cmp r1, $1				@ do we need to init uart?
	blne _uart_init

_uart_tbuffer:
	/* count n.o bytes in str, appened \r char to str after \n char and
	   put on a heap - output starts at 0xf8000, input starts at 0xf9000*/
	ldrb r1, [r0], $1
	mov r2, $'\r'
	mov r12, $0xf8000			@ assending heap

_size_t:
	cmp r1, $'\n'
	streqb r2, [r12], $1
	bic r12, r12, $0x1000			@ ensure a looping buffer
	strb r1, [r12], $1
	bic r12, r12, $0x1000			@ ensure a looping buffer
	teq r1, $0
	ldrneb r1, [r0], $1
	bne _size_t

	sbc r0, r12, $0xf8000			@ r0 holds n.o char
	mov r12, $0xf8000

	/* and at last transmit */
	ldr r3, Uart0_Base
_u_puts:
	ldr r1, [r3, $0x18]			@ tst state of fifo
	tst r1, $(1<<5)

	ldreqb r2, [r12], $1			@ put byte on fifo if room
	streqb r2, [r3]
	subeqs r0, r0, $1

	bpl _u_puts

	ldr r3, =UartLck
	mov r0, $0
	swp r0, r0, [r3]			@ unlock mutex

	ldmfd sp!, {pc}				@ return

Uart0_Base:
	.word 0x20201000
Gpio_Base:
	.word 0x20200000

_uart_r:
	/* To enable reception, disable uart, wait for end of transmision/
	   reception, flush fifo by seting fen bit to 0 in uart_lcrh, 
	   reprogram uart_cr, enable uart.
	   swp instruction used to implement a mutex with UartLck 
	*/
	ldr r3, =UartLck
	mov r2, $1
	swp r2, r2, [r3]			@ tst if locked for use
						@  if not lock and continue
	cmp r2, $0
	mvnne r0, $0
	bxne lr					@ exit if can't continue

	stmfd sp!, {lr}
	ldr r3, =UartInit
	ldr r2, [r3]
	cmp r2, $1				@ has uart been configured?
	blne _uart_init

	ldr r3, Uart0_Base
_ur1:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<4)				@ is tx/rx fifo empty?
	tstne r2, $(1<<7)
	beq _ur1

_ur2:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<3)
	bne _ur2				@ ensure not busy

	mov r12, $0xf9000

	/* Finally get to recieve something */
	/* 1 off tst that fifo filling. ldrb from dr reg, cmp data 0,
	   str data on heap, tst fifo and loop if neither 0
	*/
_u_gets:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<4)				@ fifo empty
	bne _u_gets

	ldrb r2, [r3]
	strb r2, [r12], $1
	bic r12, $0x2000
	cmp r2, $0xa
	bne _u_gets

	mov r0, $0
	strb r0, [r12]
	ldr r3, =UartLck
	swp r0, r0, [r3]			@ unlock mutex

	mov r0, $0xf9000
	ldmfd sp!, {pc}				@ return

	/* recieve a char from remote connection, echo it back, str in 
	   input buffer starting at 0xf9000
	*/  
_rxtx_char:
	ldr r3, Uart0_Base
	ldr r12, =StdIn
	mov r1, $0xa
_gc1:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<7)				@ is tx fifo empty?
	beq _gc1

_gc2:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<3)
	bne _gc2				@ ensure not busy

_gc3:
	ldr r2, [r3, $0x18]
	tst r2, $(1<<4)				@ is rx fifo not empty
	bne _gc3

	ldrb r0, [r3]
	strb r0, [r12], $1			@ save it on input buffer
	bic r12, r12, $0x400			@ looping buffer
	strb r0, [r3]				@ echo
	cmp r0, $'\r'				@ insert \n after \r
	streqb r1, [r12], $1
	bic r12, r12, $0x400			@ looping buffer
	streqb r1, [r3]

	b _gc1					@ temp endless loop


	.data
	.align 2

UartInit:
	.word 0

UartLck:
	.word 0

