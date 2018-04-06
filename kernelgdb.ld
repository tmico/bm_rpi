/* Linker script to allow kernelgdb to work in gdb */

SECTIONS
{
	. = 0x10000;
	.init : {
		*(.init)
	}
	.text : { 
		*(.interupts)
		*(.main)
		*(.text)
	 }

	.data : { 
		*(.data) 
	}

	.ebss : {
		 *(.ebss)
	 }

}
