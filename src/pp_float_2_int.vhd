-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;


--! @brief Component for converting a floating-point number to an integer result and store into an integer register.

----fcvt.wu.s
---Convert a floating-point number in floating-point register rs1 to a signed 32-bit in unsigned integer register rd.


entity pp_float_2_int is
    port(
        frd_data_in : in std_logic_vector(31 downto 0); --! Input floating-point number in IEEE 754 format.
        alu_op_in : in alu_operation; --! ALU operation to perform (should be ALU_FCVT_WU for this component).
        rd_data_out   : out std_logic_vector(31 downto 0) --! Output integer result in two's complement format.
    );
end entity;

architecture rtl of pp_float_2_int is

begin

    process(frd_data_in, alu_op_in)
        variable sign        : std_logic;
        variable exponent    : unsigned(7 downto 0);
        variable fraction    : unsigned(22 downto 0);
        variable mantissa    : unsigned(23 downto 0);
        variable exp_unbias  : integer;
        variable result      : signed(31 downto 0);
        variable shift       : integer;
    begin

        result := (others => '0');

        if alu_op_in = ALU_FCVT_WU then
            -- Unsigned conversion: FP → unsigned 32-bit integer

            -- Extract fields
            sign     := frd_data_in(31);
            exponent := unsigned(frd_data_in(30 downto 23));
            fraction := unsigned(frd_data_in(22 downto 0));

            -- Zero / subnormal
            if exponent = 0 then
                result := (others => '0');

            -- NaN or Inf
            elsif exponent = 255 then
                if fraction /= 0 then
                    -- NaN → max unsigned
                    result := (others => '1');  -- 0xFFFFFFFF
                elsif sign = '0' then
                    -- +Inf → max unsigned
                    result := (others => '1');  -- 0xFFFFFFFF
                else
                    -- -Inf → 0
                    result := (others => '0');
                end if;

            -- Negative number → 0
            elsif sign = '1' then
                result := (others => '0');

            else
                -- Add hidden 1
                mantissa := "1" & fraction;

                -- Remove bias
                exp_unbias := to_integer(exponent) - 127;

                if exp_unbias < 0 then
                    result := (others => '0');

                elsif exp_unbias > 31 then
                    -- Overflow
                    result := (others => '1');

                else
                    shift := exp_unbias - 23;

                    if shift >= 0 then
                        result := signed(shift_left(resize(mantissa, 32), shift));
                    else
                        result := signed(shift_right(resize(mantissa, 32), -shift));
                    end if;
                end if;
            end if;

        elsif alu_op_in = ALU_FCVT_W then
            -- Signed conversion: FP → signed 32-bit integer

            -- Extract fields
            sign     := frd_data_in(31);
            exponent := unsigned(frd_data_in(30 downto 23));
            fraction := unsigned(frd_data_in(22 downto 0));

            -- Zero / subnormal
            if exponent = 0 then
                result := (others => '0');

            -- NaN or Inf
            elsif exponent = 255 then
                if fraction /= 0 then
                    -- NaN → max positive signed
                    result := to_signed(2147483647, 32);  -- 0x7FFFFFFF
                else
                    -- ±Inf (return max overflow value)
                    if sign = '1' then
                        result := to_signed(-2147483648, 32); -- -2^31
                    else
                        result := to_signed(2147483647, 32);  -- 2^31 - 1
                    end if;
                end if;

            else
                -- Add hidden 1
                mantissa := "1" & fraction;

                -- Remove bias
                exp_unbias := to_integer(exponent) - 127;

                if exp_unbias < 0 then
                    result := (others => '0');

                elsif exp_unbias >= 31 then
                    -- Overflow
                    if sign = '1' then
                        result := to_signed(-2147483648, 32); -- -2^31
                    else
                        result := to_signed(2147483647, 32);  -- 2^31 - 1
                    end if;

                else
                    shift := exp_unbias - 23;
                    
                    if shift >= 0 then
                        result := signed(shift_left(resize(mantissa, 32), shift));
                    else
                        result := signed(shift_right(resize(mantissa, 32), -shift));
                    end if;

                    -- Apply sign
                    if sign = '1' then
                        result := -result;
                    end if;
                end if;
            end if;

        end if;

        rd_data_out <= std_logic_vector(result);

    end process;

end architecture;
