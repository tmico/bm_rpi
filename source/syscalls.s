
/* Syscalls - work in progress */

	.text
	.align 2

	.global _sys_write
_sys_write:
	cmp r0, $1				@ fd 1 = StdOut
	mov r11, lr				@ preserve lr
	blne _get_fd
	cmp r2, $0x1000				@ if > than max then...
	ldrhs r2, =$0x999			@ ...set string length to max
	
_get_lock:	
	ldr r6, =LockStdOut
	ldrex r3, [r6]
	mov r4, $1
	cmp r3, $0
	strexeq r3, r4, [r6]
	cmpeq r3, $0
	bne _get_lock
	
	ldrb r5, [r1], $1			@ move string to StdOut buffer
	ldr r7, =StdOut
_ms:
	subs r2, r2, $1
	strneb r5, [r7], $1
	ldrneb r5, [r1], $1
	bne _ms
	mov r5, $0
	strb r5, [r7], $1
	mov lr, r11
	bx lr
	
	
_get_fd:	
	/*ToDo setup a proper file descriptor table */
	bx lr					@ FD not implimented yet so return...
						@ ...safly

