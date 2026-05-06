-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_utilities.all;

--! @brief 32-bit RISC-V register file with integer and floating-point registers.
entity pp_fpu_register_file is
	port(
		clk    : in std_logic;

		---- fpu 2025--------

		-- Floating-point register read port 1:
		frs1_addr : in  register_address;
		frs1_data : out std_logic_vector(31 downto 0);

		-- Floating-point register read port 2:
		frs2_addr : in  register_address;
		frs2_data : out std_logic_vector(31 downto 0);

		-- Floating-point register write port:
		frd_addr  : in register_address;
		frd_data  : in std_logic_vector(31 downto 0);
		frd_write : in std_logic
	);
end entity pp_fpu_register_file;

architecture behaviour of pp_fpu_register_file is

	--! Register array type.
	type regfile_array is array(0 to 31) of std_logic_vector(31 downto 0);

begin

	regfile: process(clk)
		
		variable fp_registers : regfile_array := (
			0  => x"00000000",  -- f0  = 0.0
			1  => x"40490FDA",  -- f1  = 3.14159 (Pi)
			2  => x"402DF84D",  -- f2  = 2.71828 (e)
			3  => x"00000000",  -- f3  = reserved
			4  => x"00000000",  -- f4  = reserved
			5  => x"00000000",  -- f5  = reserved
			6  => x"00000000",  -- f6  = reserved
			7  => x"3F800000",  -- f7  = 1.0
			8  => x"00000000",  -- f8  = 0.0
			9  => x"00000000",  -- f9  = reserved
			10 => x"72C4653C",  -- f10 = 1.0e30 (very large)
			11 => x"0DA24260",  -- f11 = 1.0e-30 (very small)
			12 => x"00000000",  -- f12 = reserved
			13 => x"00000000",  -- f13 = reserved
			14 => x"7F800000",  -- f14 = +Infinity
			15 => x"7FC00000",  -- f15 = NaN
			others => x"00000000"
		);
	begin
		if rising_edge(clk) then
				
				---- fpu 2025--------

				-- Floating-point register write (f0 is NOT hardwired to zero):
				if frd_write = '1' then
					fp_registers(to_integer(unsigned(frd_addr))) := frd_data;
				end if;
		end if;

		---- fpu 2025--------

		-- Floating-point register reads (combinational, outside clock):
		frs1_data <= fp_registers(to_integer(unsigned(frs1_addr)));
		frs2_data <= fp_registers(to_integer(unsigned(frs2_addr)));
	end process regfile;

end architecture behaviour;
