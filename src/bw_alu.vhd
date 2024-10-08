-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

-- Based on:
-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;

--! @brief
--!	Arithmetic Logic Unit (ALU).
entity bw_alu is
	port(
		x, y      : in  std_logic_vector(31 downto 0);
		result    : out std_logic_vector(31 downto 0);
		operation : in alu_operation                  
	);
end entity bw_alu;

architecture behaviour of bw_alu is
begin
	calculate: process(operation, x, y)
	begin
		case operation is
			when ALU_AND =>
				result <= x and y;
			when ALU_OR =>
				result <= x or y;
			when ALU_XOR =>
				result <= x xor y;
			when ALU_SLT =>
				if signed(x) < signed(y) then
					result <= (0 => '1', others => '0');
				else
					result <= (others => '0');
				end if;
			when ALU_SLTU =>
				if unsigned(x) < unsigned(y) then
					result <= (0 => '1', others => '0');
				else
					result <= (others => '0');
				end if;
			when ALU_SLL =>
				result <= std_logic_vector(shift_left(unsigned(x), to_integer(unsigned(y(4 downto 0)))));
			when ALU_SRL =>
				result <= std_logic_vector(shift_right(unsigned(x), to_integer(unsigned(y(4 downto 0)))));
			when ALU_SRA =>
				result <= std_logic_vector(shift_right(signed(x), to_integer(unsigned(y(4 downto 0)))));
			when others =>
				result <= (others => '0');
		end case;
	end process calculate;

end architecture behaviour;
