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
		funct3   : in  std_logic_vector(2 downto 0);
        alu_op_in : in alu_operation;
		frs1, frs2 : in  std_logic_vector(31 downto 0);
		result   : out std_logic; --! Result of the comparison (goes to integer register)
		invalid_op : out std_logic --! Invalid operation exception (signaling NaN)
	);
end entity fp_pp_comparator;

architecture behaviour of fp_pp_comparator is
	-- NaN detection signals
	signal frs1_is_nan : std_logic;
	signal frs2_is_nan : std_logic;
	signal frs1_is_snan : std_logic;  -- Signaling NaN
	signal frs2_is_snan : std_logic;
	signal either_nan : std_logic;
	signal either_snan : std_logic;
	
	-- Zero comparison (handle +0 = -0)
	signal frs1_is_zero : std_logic;
	signal frs2_is_zero : std_logic;
begin

	-- NaN: exponent = 0xFF and mantissa != 0
	frs1_is_nan <= '1' when (frs1(30 downto 23) = "11111111" and frs1(22 downto 0) /= "00000000000000000000000") else '0';
	frs2_is_nan <= '1' when (frs2(30 downto 23) = "11111111" and frs2(22 downto 0) /= "00000000000000000000000") else '0';
	
	-- Signaling NaN: NaN with mantissa[22] = 0 (quiet bit not set)
	frs1_is_snan <= '1' when (frs1_is_nan = '1' and frs1(22) = '0') else '0';
	frs2_is_snan <= '1' when (frs2_is_nan = '1' and frs2(22) = '0') else '0';
	
	either_nan <= frs1_is_nan or frs2_is_nan;
	either_snan <= frs1_is_snan or frs2_is_snan;
	
	-- Zero detection: exponent = 0 and mantissa = 0 (ignore sign)
	frs1_is_zero <= '1' when (frs1(30 downto 0) = "0000000000000000000000000000000") else '0';
	frs2_is_zero <= '1' when (frs2(30 downto 0) = "0000000000000000000000000000000") else '0';

	compare_fp: process(funct3, alu_op_in, frs1, frs2, either_nan, either_snan, frs1_is_zero, frs2_is_zero, frs1_is_nan, frs2_is_nan)
	begin
		invalid_op <= '0';
		result <= '0';
		
        if alu_op_in = ALU_Comp then
			case funct3 is
				when b"010" => -- FEQ.S (quiet equal)
					-- Result is 0 if either operand is NaN
					if either_nan = '1' then
						result <= '0';
						-- Only signaling NaN raises Invalid Operation
						invalid_op <= either_snan;
					-- +0 equals -0 in IEEE 754
					elsif (frs1_is_zero = '1' and frs2_is_zero = '1') then
						result <= '1';
					else
						result <= to_std_logic(frs1 = frs2);
					end if;
					
				when b"001" => -- FLT.S (less than, signaling)
					-- Any NaN (quiet or signaling) raises Invalid Operation for FLT
					if either_nan = '1' then
						result <= '0';
						invalid_op <= '1';  -- FLT signals on ALL NaNs
					elsif (frs1_is_zero = '1' and frs2_is_zero = '1') then
						result <= '0';  -- +0 is not less than -0
					else
						---result <= to_std_logic(signed(frs1) < signed(frs2));
					if frs1(31) /= frs2(31) then
    					result <= frs1(31); -- if frs1 is negative, it is smaller
					else
 					if frs1(31) = '0' then
 					    -- both positive
 					    if unsigned(frs1(30 downto 23)) < unsigned(frs2(30 downto 23)) then
 					        result <= '1';
 					    elsif frs1(30 downto 23) = frs2(30 downto 23) then
 					        result <= to_std_logic(frs1(22 downto 0) < frs2(22 downto 0));
 					    else
 					        result <= '0';
 					    end if;
    				else
       					-- both negative → reverse
       					if unsigned(frs1(30 downto 23)) > unsigned(frs2(30 downto 23)) then
       					    result <= '1';
       					elsif frs1(30 downto 23) = frs2(30 downto 23) then
       					    result <= to_std_logic(frs1(22 downto 0) > frs2(22 downto 0));
       					else
       					    result <= '0';
       					end if;
    					end if;
					end if;
					end if;
					
				when b"000" => -- FLE.S (less or equal, signaling)

    			if either_nan = '1' then
        			result <= '0';
        			invalid_op <= '1';

    			elsif (frs1_is_zero = '1' and frs2_is_zero = '1') then
        			result <= '1';

				else
				    -- Different signs
				    if frs1(31) /= frs2(31) then
				        result <= frs1(31);  -- negative <= positive = true

		    -- Same sign
		    	else
		        	if frs1(31) = '0' then
		        	    -- Both positive
		        	    if unsigned(frs1(30 downto 23)) < unsigned(frs2(30 downto 23)) then
		        	        result <= '1';
		        	    elsif frs1(30 downto 23) = frs2(30 downto 23) then
		        	        result <= to_std_logic(frs1(22 downto 0) <= frs2(22 downto 0));
		        	    else
		        	        result <= '0';
		        	    end if;
		        else
		            -- Both negative → reverse comparison
		            if unsigned(frs1(30 downto 23)) > unsigned(frs2(30 downto 23)) then
		                result <= '1';
		            elsif frs1(30 downto 23) = frs2(30 downto 23) then
		                result <= to_std_logic(frs1(22 downto 0) >= frs2(22 downto 0));
		            else
		                result <= '0';
		            end if;
		        end if;
		    end if;
		end if;

				when others =>
					result <= '0';
			end case;
        end if;
	end process compare_fp;

end architecture behaviour;
