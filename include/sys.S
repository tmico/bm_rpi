/*
 * List of Memory mapped constants
 */

@--	.if DEBUG != 1			@ Different values if debug
.equ 	DMA0,		0x20007000	@ DMA channel 0

.equ	MAILBASE,	0x2000b880	@ Mailbox base
.equ	MAILREAD,	0x2000b880	@ Mailbox read
.equ	MAILWRITE,	0x2000b8a0	@ Mailbox write
.equ	GPIOBASE,	0x20200000	@ gpio controller base addr
.equ	GPIOCLR0,	0x20200028	@ gpio clear
.equ	GPIOSET0,	0x2020001c	@ gpio set

.equ	GPUADDR,	0x40000000	@ gpu mailbox addr

@--	.else
