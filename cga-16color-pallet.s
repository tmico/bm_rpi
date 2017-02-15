/* cga 16 color palette */
/*
 * 0	black		0x000000
 * 1	blue		0x0000AA
 * 2	green		0x00AA00
 * 3	cyan		0x00AAAA
 * 4	red		0xAA0000
 * 5	mangeta		0xAA00AA
 * 6	brown		0xAA5500
 * 7	light grey	0xAAAAAA
 * 8	grey		0x555555
 * 9	light blue	0x5555FF
 * 10	light green	0x55FF55
 * 11	light cyan	0x55FFFF
 * 12	light red	0xFF5555
 * 13	light mangeta	0xFF55FF
 * 14	yellow		0xFFFF55
 * 15	white		0xFFFFFF
 */

	.data
	.global cga_16color
cga_16color:
	.int	0x000000
	.int	0x0000aa
	.int	0x00aa00
	.int	0x00aaaa
	.int	0xaa0000
	.int	0xaa00aa
	.int	0xaa5500
	.int	0xaaaaaa
	.int	0x555555
	.int	0x5555ff
	.int	0x55ff55
	.int	0x55ffff
	.int	0xff5555
	.int	0xff55ff
	.int	0xffff55
	.int	0xffffff
