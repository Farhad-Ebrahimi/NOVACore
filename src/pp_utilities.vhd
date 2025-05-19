-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

use work.pp_types.all;
use work.pp_constants.all;

package pp_utilities is

	--! Converts a boolean to an std_logic.
	function to_std_logic(input : in boolean) return std_logic;

	-- Checks if a number is 2^n:
	function is_pow2(input : in natural) return boolean;

	--! Calculates log2 with integers.
	function log2(input : in natural) return natural;

	-- Gets the value of the sel signals to the wishbone interconnect for the specified
	-- operand size and address.
	function wb_get_data_sel(size : in std_logic_vector(1 downto 0); address : in std_logic_vector)
		return std_logic_vector;
	
    -- Function to identify CSD-type ALU operations
    function is_csd_op(op : alu_operation) return boolean;
    
    -- Function to check if address is within memory range
    function is_mem_addr(addr : std_logic_vector(31 downto 0)) return boolean;
    
    -- Memory function
    function get_selected_memory(mem_address : std_logic_vector(31 downto 0)) return memory_region_t ;

end package pp_utilities;

package body pp_utilities is

  function is_csd_op(op : alu_operation) return boolean is
  begin
    return (
       op = ALU_ADD  or
       op = ALU_SUB  or
       op = ALU_MUL  or
       op = ALU_MULH or
       op = ALU_MULHU or
       op = ALU_MULHSU
    );
  end function;
  
    function is_mem_addr(addr : std_logic_vector(31 downto 0)) return boolean is
    begin
        case addr(31 downto 16) is
            when x"0000" | x"0001" => return true;
            when x"FFFF" =>
               case addr(15 downto 10) is
                when b"100000" | b"100001" | b"100010" | b"100011" | b"100100" =>
                    return true;
                when others =>
                    return false;
            end case; 
            when others => return false;
        end case;
    end function;
    
    function get_selected_memory(mem_address : std_logic_vector(31 downto 0)) return memory_region_t is
        variable mem : memory_region_t;
    begin
        if mem_address(31 downto 16) = x"0000" or mem_address(31 downto 16) = x"0001" then
            mem := MAIN_MEM;
        elsif mem_address(31 downto 16) = x"FFFF" then
            case mem_address(15 downto 10) is
                when b"100000" =>
                    mem := FSBL_ROM;
                when b"100001" | b"100010" =>
                    mem := SSBL_SRAM;
                when b"100011" | b"100100" =>
                    mem := AEE_SRAM;
                when others =>
                    mem := NON_MEM;
            end case;
        else
            mem := NON_MEM;
        end if;
    return mem;
    end function;

	function to_std_logic(input : in boolean) return std_logic is
	begin
		if input then
			return '1';
		else
			return '0';
		end if;
	end function to_std_logic;

	function is_pow2(input : in natural) return boolean is
		variable c : natural := 1;
	begin
		for i in 0 to 31 loop
			if input = c then
				return true;
			end if;

			c := c * 2;
		end loop;

		return false;
	end function is_pow2;

	function log2(input : in natural) return natural is
		variable retval : natural := 0;
		variable temp   : natural := input;
	begin
		while temp > 1 loop
			retval := retval + 1;
			temp := temp / 2;
		end loop;

		return retval;
	end function log2;

	function wb_get_data_sel(size : in std_logic_vector(1 downto 0); address : in std_logic_vector)
		return std_logic_vector is
	begin
		case size is
			when b"01" =>
				if address(1 downto 0) = "00" then
                    return "0001";
                elsif address(1 downto 0) = "01" then
                    return "0010";
                elsif address(1 downto 0) = "10" then
                    return "0100";
                elsif address(1 downto 0) = "11" then
                    return "1000";
                else
                    return "0001"; -- Default case, handling 'others' scenario
                end if;
			when b"10" =>
				if address(1) = '0' then
					return b"0011";
				else
					return b"1100";
				end if;
			when others =>
				return b"1111";
		end case;
	end function wb_get_data_sel;

end package body pp_utilities;
