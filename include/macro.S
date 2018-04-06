/* User macro's
================================================================================
*/
/* armv6 lacks a Data Memory Barrier opp code, This macro
 * will substitute DMB with armv6 instructions for one
 */
.macro DMB
mov r3, $0
mcr p15, 0, r3, c7, c10, 5
.endm
