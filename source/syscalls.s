
/* Syscalls - work in progress */
@@@ re-do! some thought needed to design some kind of basic fd table  
	.text
	.align 2

	.global _sys_write
	/* Input: r0 = fd, r1 = &STRING, r2 = SIZE (bytes (inc NULL byte))
	 */
_sys_write:
	cmp r0, $1				@ fd 1 = StdOut
	mov r12, lr				@ preserve lr
	blne _get_fd
	mov r0, r1
	mov r1, r2
	blx r3
	
	mov lr, r12
	bx lr
	
	
_get_fd:	
	/*ToDo setup a proper file descriptor table */
	
	ldr r0, =FdTable
	ldr r3, [r0]
	bx lr	
		
	.data
	.align 2
FdTable:
	.word _tty_console_in
	/* jump/switch table for syscalls */
	.global SysCall
SysCall:
	
	 .word 0                                 @ sys_read
	 .word 0                                 @ sys_open
	 .word 0                                 @ sys_close
	 .word _sys_write                        @ sys_write
