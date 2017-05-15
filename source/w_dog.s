
	/* code from adapted from w_dog.c file written by dwelch.*/
	.align	2
	.global	_reboot_system
.equ PM_BASE, 0x20100000
.equ PM_PASSWORD, 0x5a000000
.equ PM_RSTC_OFFSET, 0x1c
.equ PM_WDOG_OFFSET, 0x24
.equ PM_WDOG_TIME_SET, 0x000fffff
.equ PM_RSTC_WRCFG_CLR, 0xffffffcf
.equ PM_RSTC_WRCFG_SET, 0x00000030
.equ PM_RSTC_WRCFG_FULL_RESET, 0x00000020
.equ PM_RSTC_RESET, 0x00000102

	
_reboot_system:
	ldr r0, =PM_BASE
	mov r2, $PM_PASSWORD
	orr r1, r2, $0x800
	ldr r3, [r0, $PM_RSTC_OFFSET]
	str r1, [r0, $PM_WDOG_OFFSET]
	orr r1, r2, $0x20
	bic r3, r3, $0x10
	orr r1, r1, r3
	str r1, [r0, $PM_RSTC_OFFSET]
_L:
	nop
	b _L
