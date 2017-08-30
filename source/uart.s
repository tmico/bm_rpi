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
	.global _uart_ctr
	.global _uart_r
	.global _rxtx_char
	.global _uart_exep
_uart_init:
	/* Entry point to this function is from uart_ctr. _uart_init is a once only
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
	ldr r3, =UartInfo
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

_uart_ctr:
	/*Input R0: address of string to send 
	  Return R0: 0 = success, 1 = blocked wait, 
	/* To enable transmision, disable uart, wait for end of transmision,
	   flush fifo by seting fen bit to 0 in uart_lcrh, reprogram uart_cr,
	   enable uart.
	   swp instruction used to implement a mutex with UartLck pre armv6
	ldr r3, =UartLck
	mov r2, $1				@ 1 = in use, 0 free mutex
	swp r2, r2, [r3]			@ semaphore: atomic ldr and str
	cmp r2, $0				@ can we carry on?
	bne _uart_ctr				@ a spin lock
	armv6 it is recomened to use ldrex/strex to implement a mutex. 
	*/
	/* TODO add checks not reciving data before sending, disable receive bit while sending */


	ldr r3, =UartLck
	mov r1, $1
	ldrex r2, [r3]
	cmp r2, $0				@ free?
	strexeq r2, r1, [r3]			@ Attempt to lock it
	cmpeq r2, $0				@ 0 = success, 1 = fail
	bne _uart_ctr

	stmfd sp!, {r4, r5, lr}
	ldr r5, =UartInfo
	ldr r1, [r5]
	cmp r1, $1				@ do we need to init uart?
	blne _uart_init

	/* Check that buffer is empty, if not can we allow buffer
	   to be emptied onto uart's fifo? */
	ldr r1, [r5, $12]			@ Is there existing string address
	cmp r1, $0
	streq r0, [r5, $12]			@ Save address of string

_ctr:
	ldr r1, [r5, $8]			@ Is Buffer empty
	cmp r1, $0
	bleq _uart_put_buffer

	/* branch to put chars on the uart fifo */
	bl _uart_puts
	cmp r0, $1				@ has it completed?
	subeq pc, pc, $16

	/* If There is more to print return non zero */
	ldr r0, [r5, $12]			@ String fully --> buffer?
	cmp r0, $0				@@ next two lines can be supplanted with a process manager
	bne _ctr

	ldr r3, =UartLck			@ unlock
	mov r1, $0
	str r1, [r3]			
	/*DMB	--trigers an undfined excption in armv6 so need to use p15
	 (see pg 217 of arm1176ijf-s) */
	mcr p15, 0, r1, c7, c10, 5 		@ DMB

	

	ldmfd sp!, {r4, r5, pc}
UartLck:
	.word 0

	/*Tranfer from address in r0 into UartTxBuffer. Number of char (bytes)
	  is put into r12 */
_uart_put_buffer:
	ldr r0, [r5, $12]
	ldrb r1, [r0], $1
	ldr r3, =UartTxBuffer			@ ldr 128byte buffer
	mov r12, $128				@ Max size
	mov r2, $'\r'				@ insert after a '\n'
_tb:
	cmp r1, $'\n'

	streqb r2, [r3], $1
	subeq r12, r12, $1

	strb r1, [r3], $1
	subs r12, r12, $1
	cmpne r1, $0				@ Continue till Null char or full
	ldrneb r1, [r0], $1
	bne _tb

	cmp r1, $0
	rsb r12, r12, $128			@ r12 now holds no chars
	str r12, [r5, $8]
	strne r0, [r5, $12]			@ save current location
	streq r1, [r5, $12]			@ Or indicate copy finnished
	bx lr
	

	/* Check if fifo is not full */
_chk_txfifo:
	ldr r2, Uart0_Base
	ldr r1, [r2, $0x18]
	tst r1, $(1<<5)				@ tst if fifo is full
	movne r0, $1				@ 1 if blocked
	moveq r0, $0				@ 0 if can continue
	bx lr
	

	/*Transmit whats in buffer, r0,r1 preserved*/
_uart_puts:
	stmfd sp!, {lr}
	bl _chk_txfifo				@ check there is room
	cmp r0, $0				@ 0 continue, 1 stop full
	ldmnefd sp!, {pc}

	ldr r3, =UartTxBuffer
	ldr r2, Uart0_Base
	ldr r12, [r5, $8]			@ get number of char in buffer
	ldr r4, [r5, $4]			@ get offset to uartbuffer
	ldrb r1, [r3, r4]
_pc:
	add r4, r4, $1
	strb r1, [r2]				@ put char onto fifo
	subs r12, r12, $1
	beq _buffer_empty
	bl _chk_txfifo
	cmp r0, $0				@ can we continue?
	ldreqb r1, [r3, r4]
	beq _pc

	str r12, [r5, $8]			@ save chars left for later
	str r4, [r5, $4]			@ save offset
	ldmfd sp!, {pc}

_buffer_empty:
	mov r4, $0
	str r4, [r5, $4]
	str r4, [r5, $8]
	
	ldmfd sp!, {pc}
	

Uart0_Base:
	.word 0x20201000
Gpio_Base:
	.word 0x20200000

_uart_r:
	/* To enable reception, disable uart, wait for end of transmision/
	   reception, flush fifo by seting fen bit to 0 in uart_lcrh, 
	   reprogram uart_cr, enable uart.
	   ldrex/strex instruction used to implement a mutex with UartLck 
	*/
	ldr r3, =UartLck
	mov r1, $1
	ldrex r2, [r3]
	cmp r2, $0				@ free?
	strexeq r2, r1, [r3]			@ Attempt to lock it
	cmpeq r2, $0				@ 0 = success, 1 = fail...
	bne _uart_r				@ ...if not locked continue

	cmp r2, $0
	mvnne r0, $0
	bxne lr					@ exit if can't continue

	stmfd sp!, {lr}
	ldr r3, =UartInfo
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
	str r0, [r3]
	/*DMB	--trigers an undfined excption in armv6 so need to use p15
	 (see pg 217 of arm1176ijf-s) */
	mcr p15, 0, r1, c7, c10, 5 		@ Perform DMB ...

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

UartInfo:
	.word 0		@ #0 UartInit
	.word 0		@ #4 BufferOffset,
	.word 0		@ #8 BufferFill, no of chars in buffer
	.word 0		@ #12 string address


UartTxBuffer:
	.rept 0x80				@ 128 byte buffer
	.byte 0
	.endr
StdIn:	@-- Temp here to allow compiling. One of many things to sort out!!! patience :)
