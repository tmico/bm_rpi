/* this file is not intented to hold any instuctions but rather
 * a loosish collection of .data values, files, whatever that i didn't feel
 * i wanted to be in main.s and were not needed by any other funtion to warrent
 * including them in other *s files
 */

	.section .data
	.align 2
	.global FabPic

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
	
