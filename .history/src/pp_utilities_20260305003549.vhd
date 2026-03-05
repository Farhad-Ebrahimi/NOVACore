-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    function wb_get_data_sel(size : in std_logic_vector(1 downto 0); address : in std_logic_vector
    ) return std_logic_vector;

    -- Function to identify CSD-type ALU operations
    function is_csd_op(op : alu_operation) return boolean;


    ---Function to identify All floating point operations (write 1)
    function is_fp_op(op : alu_operation) return boolean;
    
        --Function to identify 3 cycled floating point operations
    function if_fp_arith_op(input : in alu_operation) return boolean;


    function if_fp_to_int_op(input : in alu_operation) return boolean;

    -- Function to check if address is within memory range
    function is_mem_addr(addr : std_logic_vector(31 downto 0)) return boolean;

    -- Memory selection function based on address ranges
    function get_selected_memory(mem_address : std_logic_vector(31 downto 0)) return natural;

    function get_data_shift(size : in std_logic_vector(1 downto 0); address : in std_logic_vector
    ) return natural;

end package pp_utilities;

package body pp_utilities is
    function get_data_shift(size : in std_logic_vector(1 downto 0); address : in std_logic_vector)
        return natural is
    begin
        case size is
            when b"01" =>
                if address(1 downto 0) = "00" then
                    return 0;
                elsif address(1 downto 0) = "01" then
                    return 8;
                elsif address(1 downto 0) = "10" then
                    return 16;
                elsif address(1 downto 0) = "11" then
                    return 24;
                else
                    return 0;
                end if;
            when b"10" =>
                if address(1) = '0' then
                    return 0;
                else
                    return 16;
                end if;
            when others =>
                return 0;
        end case;
    end function;
    function is_csd_op(op : alu_operation) return boolean is
    begin
        return (
        op = ALU_ADD or
        op = ALU_SUB or
        op = ALU_MUL or
        op = ALU_MULH or
        op = ALU_MULHU or
        op = ALU_MULHSU
        );
    end function;

    function is_fp_op(op : alu_operation) return boolean is
    begin
        return (
        op = ALU_FADD or
        op = ALU_FSUB or
        op = ALU_FMUL or
        op = ALU_FDIV or
        op = ALU_FCVT_S_W or
        op = ALU_FCVT_S_WU or
        op = ALU_FMVWX
        );
    end function;
   ----output is available at the end of stage3 only not before so if we have some
   ----instructions after this that needs to read the result of this instruction then
    --- we need to stall the pipeline until the result is available in stage3
    -----so stall for 1 cycle
    function if_fp_arith_op(input : in alu_operation) return boolean is
        begin
            return (
            input = ALU_FADD or
            input = ALU_FSUB or
            input = ALU_FMUL or
            input = ALU_FDIV
            );
        end function;


    -----reads floats 
    function if_fp_to_int_op(input : in alu_operation) return boolean is
        begin
            return (
            input = ALU_FCVT_S_W or
            input = ALU_FCVT_S_WU or
            input = ALU_FMVWX or
            input = ALU_FEQ or
            input = ALU_FLE or
            input = ALU_FLT
            );
        end function;

    function is_mem_addr(addr : std_logic_vector(31 downto 0))
        return boolean is
    begin
        case addr(31 downto 16) is
            -- 0x0000_0000 → 0x0007_FFFF
            when x"0000" | x"0001" | x"0002" |x"0003" |x"0004" |x"0005" | x"0006" | x"0007" =>
                return true;
            -- 0xFFFF_xxxx region
            when x"FFFF" =>
                case addr(15 downto 10) is
                    when b"100000" | b"100001" | b"100010" =>
                        return true;
                    when others =>
                        return false;
                end case;
            when others =>
                return false;
        end case;

    end function;
    function get_selected_memory(
        mem_address : std_logic_vector(31 downto 0)
    ) return natural is
        variable mem : natural := 0; -- default
    begin
        -- Main memory: 0x0000_0000 to 0x0007_FFFF (512 KB)
        if unsigned(mem_address(31 downto 16)) < x"0008" then
            mem := 8;
            -- Boot region: 0xFFFF_xxxx
        elsif unsigned(mem_address(31 downto 16)) = x"FFFF" then
            case mem_address(15 downto 10) is
                when b"100000" =>
                    mem := 1; -- FSBL
                when b"100001" | b"100010" =>
                    mem := 2; -- SSBL
                when others =>
                    mem := 0;
            end case;
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
        variable temp : natural := input;
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