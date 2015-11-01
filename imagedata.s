/* this file is not intented to hold any instuctions but rather
 * a loosish collection of .data values, files, whatever that i didn't feel
 * i wanted to be in main.s and were not needed by any other funtion to warrent
 * including them in other *s files
 */

	.section .data
	.align 2
	.global FabPic
	.global SystemFont
	.global EditUndo16
	.global Uvga16
	.global screenx
	.global screeny

.equ	screenx,	0x500

.equ	screeny,	0x2d0



FabPic:						@ picture by fabienne micoud
	.incbin		"fabs.bmp"

/* psf2 font format : - 
 *	1. The header
 *	2. The font
 *	3. The unicode infomation 
 *		structure of psf2 header
 *		0x0000 unsigned char	[32-bit magic 0x864ab572]
 *		0x0004 unsigned int	[version]
 *		0x0008 unsigned int	[header size]
 *		0x000c unsigned int	[flags]
 *		0x0010 unsigned int	[length (number of glyphs)]
 *		0x0014 unsigned int	[char size (in bytes)]
 *		0x0018 unsigned int	[height]     
 *		0x001c unsigned int	[width]     
 *	bits in flag:	0x01 file has unicode table
 *			0x00 file has no unicode table.
 *	UTF8 separators:
 *	PSF2_SEPARATOR  0xFF
 *	PSF2_STARTSEQ   0xFE
*/
	

EditUndo16:
	.incbin		"editundo.adapt16.psf"	@ Fonts created by Brian kent
						@  in psf format (bitmap) with
						@  the unicode table stripped
	
Uvga16:
	.incbin		"u_vga16.psf"


	.global CursorLoc			@ Cursor location stored in mem
CursorLoc:
	.word 0x10				@ x coordinate
	.word 0x10				@ y coordinate
	
	.global ScreenWidth
	.global CursorPos

ScreenWidth:	
	.word 0x74				@ 116 char wide based 
						@  on font width 11
CursorPos:
	.word 0x74


	.global Text1
	.global Text1lng 
Text1:
	.asciz "< Welcome to A4E O1 >"
	Text1lng = . - Text1

/* Terminal */
	.align 4
TerminalStart:
	.int TerminalBuffer			@ 1st char in buffer

TerminalEnd:
	.int TerminalBuffer			@ last char in buffer

TerminalView:
	.int TerminalBuffer			@ 1st char in buffer on screen

TerminalColour:
	.byte 0x0f

	.align 8

TerminalBuffer:
	.rept 80 * 80				
	.byte 0x7f
	.byte 0x00
	.endr

TerminalScreen:
	.rept 80 * 30
	.byte 0x7f
	.byte 0x00
	.endr
