-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

---use work.pp_utilities.all;

--! @brief Component for comparing two registers in the ID stage whens branching.
entity fp_pp_comparator is
	port(
		funct3   : in  std_logic_vector(14 downto 12);
        alu_op_in : in alu_operation;
		frs1, frs2 : in  std_logic_vector(31 downto 0);
		result   : out std_logic --! Result of the comparison. ---this will be integer register
	);
end entity fp_pp_comparator;

architecture behaviour of fp_pp_comparator is
begin

	compare_fp: process(funct3, alu_op_in, frs1, frs2)
	begin
        if alu_op_in = ALU_Comp then  -- FPU opcode
		case funct3 is
			when b"010" => -- EQ
				result <= to_std_logic(frs1 = frs2);
			when b"001" => -- LT
				result <= to_std_logic(signed(frs1) < signed(frs2));
			when b"000" => -- fle.s
				result <= to_std_logic(signed(frs1) <= signed(frs2));
			when others =>
				result <= '0';
		end case;
        else
            result <= '0';
        end if;
	end process compare_fp;

end architecture behaviour;
