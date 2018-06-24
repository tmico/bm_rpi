
/* Syscalls - work in progress */
	
@@@ re-do! some thought needed to design some kind of basic fd table  
	.text
	.align 2

	.global _sys_write
	/* Input: r0 = fd, r1 = &STRING, r2 = SIZE (bytes (inc NULL byte))
	 */
_sys_write:
	stmfd sp!, {lr}
	mov r0, r1
	mov r1, r2
	bl _uart_ctr
	ldmfd sp!, {pc}

	
_get_fd:	
	/*ToDo setup a proper file descriptor table */
	
	ldr r0, =FdTable
	ldr r3, [r0]
	bx lr	
		
	.data
	.align 2
FdTable:
	.word _tty_console_in
	/* jump/switch table for syscalls -- mimicking linux syscall.tbl */
	.global SysCall
SysCall:
	
	.word 0					@ sys_restart
	.word 0					@ sys_exit
	.word 0					@ sys_fork
	.word 0					@ sys_read
	.word _sys_write			@ sys_write
	.word 0					@ sys_open
	.word 0					@ sys_close
	
Swrite:		@ For debugging 
	.asciz "This is syscall write\n"
