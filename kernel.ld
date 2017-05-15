/******************************************************************************
	kernel.ld
	 by Thierry Micoud

	A linker script for generation of raspberry pi kernel images.
******************************************************************************/

SECTIONS {
	 /*
	 * First is init section. This is the entry point of code 
	 */
/*New boot loaders load the kernel at this address*/

	.init 0x8000 : {	
		*(.init)
	}

/*Old bootladers load kernel at address 0x0 */
/*
	.init 0x0 : {
		*(.init)
	}
*/
	/* 
	* Next we put the rest of the code. With the interupts section comming
	* first, followed by main
	*/
	.text : {
		*(.interupts)
		*(.main)
		*(.text)
	}
	
	/* 
	* Next we put the data.
	*/
	.data : {
		*(.data)
	}

	/* ebss: The end of the kernel */
	.ebss : {
		*(.ebss)
	}

	/*
	* Finally comes everything else. A fun trick here is to put all other 
	* sections into this section, which will be discarded by default.
	*/
	/*
	/DISCARD/ : {
		*(*)
	}
	*/
}
