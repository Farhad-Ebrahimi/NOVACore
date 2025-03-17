/* 
-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>
*/

ENTRY(_start)

MEMORY
{
    SSBL_RAM (rwx)  : ORIGIN = 0xffff8404, LENGTH = 0x000007FC /* 2044 B SSBL RAM */
}

SECTIONS
{
	.text :
	{
		*(.init)
		__text_begin = .;
		*(.text*)
		__text_end = .;
	} > SSBL_RAM

	.rodata :
	{
		__rodata_begin = .;
		*(.rodata*)
		__rodata_end = .;
	} > SSBL_RAM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		__data_end = .;
	} > SSBL_RAM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		__bss_end = .;
	} > SSBL_RAM

	/* Set the start of the stack to the top of SSBL_RAM */
	__stack_top = ORIGIN(SSBL_RAM) + LENGTH(SSBL_RAM);

	/DISCARD/ :
	{
		*(.comment)
	}
}

