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


	.global VirusAscii
VirusAscii:
	.incbin 	"ascii-virus.txt"

	
