-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all;

--! @brief Component for converting an integer to a single-precision floating-point number.
--! Supports both signed (FCVT.S.W) and unsigned (FCVT.S.WU) conversions.

entity pp_int_2_float is
    port(
        data_in : in std_logic_vector(31 downto 0);     --! Input integer in two's complement (or unsigned) format.
        alu_op_in : in alu_operation;                   --! ALU operation (ALU_FCVT_S_W or ALU_FCVT_S_WU).
        frd_data_out : out std_logic_vector(31 downto 0) --! Output floating-point number in IEEE 754 format.
    );
end entity pp_int_2_float;

architecture rtl of pp_int_2_float is

    -- Function to find the position of the most significant bit
    function msb_position(value : unsigned) return integer is
        variable pos : integer;
    begin
        pos := 31;
        for i in 31 downto 0 loop
            if value(i) = '1' then
                pos := i;
                exit;
            end if;
        end loop;
        return pos;
    end function;

begin

    process(data_in, alu_op_in)
        variable sign       : std_logic;
        variable input_val  : unsigned(31 downto 0);
        variable abs_val    : unsigned(31 downto 0);
        variable msb_pos    : integer;
        variable exp_val    : unsigned(8 downto 0);
        variable mantissa   : unsigned(22 downto 0);
        variable frac_bits  : unsigned(30 downto 0);
        variable result     : std_logic_vector(31 downto 0);
    begin

        if alu_op_in = ALU_FCVT_S_W then
            -- Signed conversion: signed 32-bit int → FP
            input_val := unsigned(data_in);
            
            -- Extract sign
            sign := data_in(31);
            
            -- Get absolute value
            if sign = '1' then
                abs_val := unsigned(-signed(data_in));
            else
                abs_val := input_val;
            end if;

            -- Handle zero
            if abs_val = 0 then
                result := (others => '0');
                if sign = '1' then
                    result(31) := '1';  -- -0.0
                end if;
            else
                -- Find the position of MSB (31 down to 0)
                msb_pos := msb_position(abs_val);
                
                -- Exponent: position + bias (127)
                -- MSB position 31 means 2^31, so exponent = 31 + 127 = 158
                -- MSB position 0 means 2^0, so exponent = 0 + 127 = 127
                exp_val := to_unsigned(msb_pos + 127, 9);
                
                -- Extract mantissa (23 bits after the MSB)
                if msb_pos >= 23 then
                    -- Shift right to get 23 bits after MSB
                    frac_bits := shift_right(abs_val, msb_pos - 23);
                    mantissa := frac_bits(22 downto 0);
                else
                    -- Shift left to get 23 bits after MSB
                    frac_bits := shift_left(abs_val, 23 - msb_pos);
                    mantissa := frac_bits(22 downto 0);
                end if;
                
                -- Pack IEEE 754 format: sign(1) + exponent(8) + mantissa(23)
                result := sign & std_logic_vector(exp_val(7 downto 0)) & std_logic_vector(mantissa);
            end if;

        elsif alu_op_in = ALU_FCVT_S_WU then
            -- Unsigned conversion: unsigned 32-bit int → FP
            input_val := unsigned(data_in);
            sign := '0';  -- Always positive for unsigned
            
            -- Handle zero
            if input_val = 0 then
                result := (others => '0');
            else
                -- Find the position of MSB
                msb_pos := msb_position(input_val);
                
                -- Exponent: position + bias (127)
                exp_val := to_unsigned(msb_pos + 127, 9);
                
                -- Extract mantissa (23 bits after the MSB)
                if msb_pos >= 23 then
                    frac_bits := shift_right(input_val, msb_pos - 23);
                    mantissa := frac_bits(22 downto 0);
                else
                    frac_bits := shift_left(input_val, 23 - msb_pos);
                    mantissa := frac_bits(22 downto 0);
                end if;
                
                -- Pack IEEE 754 format
                result := '0' & std_logic_vector(exp_val(7 downto 0)) & std_logic_vector(mantissa);
            end if;

        else
            -- Invalid operation
            result := (others => '0');
        end if;

        frd_data_out <= result;

    end process;

end architecture rtl;
