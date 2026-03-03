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

	fregfile: process(clk)
		
		variable fp_registers : regfile_array := (others => (others => '0'));
	begin
		if rising_edge(clk) then
				if frd_write = '1' then
					fp_registers(to_integer(unsigned(frd_addr))) := frd_data;
				end if;
				frs1_data <= fp_registers(to_integer(unsigned(frs1_addr)));
				frs2_data <= fp_registers(to_integer(unsigned(frs2_addr)));
		end if;
	end process fregfile;

end architecture behaviour;
