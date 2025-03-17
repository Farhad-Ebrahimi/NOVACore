ENTRY(_start)

MEMORY
{
    FSBL_ROM (rx)  : ORIGIN = 0xffff8000, LENGTH = 0x00000400 /* 1024 B FSBL ROM */
    SSBL_RAM (rwx) : ORIGIN = 0xffff8404, LENGTH = 0x000007FC /* 2044 B SSBL RAM */
    AEE_RAM (rw)   : ORIGIN = 0xffff8c00, LENGTH = 0x00000800 /* 2048 B AEE RAM */
    MAIN_RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00002000 /* 8196 B Main Mem */
}

SECTIONS
{
	.text :
	{
		*(.init)
		*(.text*)
		__text_end = .;
		*(.rodata*)
	} > FSBL_ROM

	.data : AT(ADDR(.text) + SIZEOF(.text))
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		__data_end = ALIGN(4);
	} > AEE_RAM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		__bss_end = .;
	} > AEE_RAM

	/* Set stack to top of MAIN_RAM */
	__stack_top = ORIGIN(MAIN_RAM) + LENGTH(MAIN_RAM);

	/DISCARD/ :
	{
		*(.comment)
	}
}
