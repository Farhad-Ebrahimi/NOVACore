library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity divider_stg3 is
  port (
    is_signed    : in std_logic;
    a_sign       : in std_logic;
    b_sign       : in std_logic;
    shift_a      : in unsigned(4 downto 0);
    shift_b      : in unsigned(4 downto 0);
    div_by_zero  : in std_logic;
    div_overflow : in std_logic;
    q_pos, q_neg : in std_logic_vector(33 downto 0);
    r_pos, r_neg : in std_logic_vector(33 downto 0);
    q            : out std_logic_vector(31 downto 0)
  );
end entity divider_stg3;

architecture behavioral of divider_stg3 is
  signal q_out        : std_logic_vector(33 downto 0);
  signal r            : std_logic_vector(33 downto 0);
  signal q_correction : std_logic;
  signal q_corrected  : unsigned(33 downto 0);
  signal q_unsigned   : std_logic_vector(31 downto 0);

begin
  q_out <= std_logic_vector(signed(q_pos) - signed(q_neg));
  r <= std_logic_vector(signed(r_pos) - signed(r_neg));

  q_correction <= '1' when r(33) = '1' else '0';
  q_corrected <= (unsigned(q_out) - to_unsigned(1, 34)) when q_correction = '1' else unsigned(q_out);

  q_unsigned <= std_logic_vector(shift_right(q_corrected, 32 - to_integer(shift_b) + to_integer(shift_a))(31 downto 0));
  q <= x"FFFFFFFF" when div_by_zero = '1' else
       x"80000000" when div_overflow = '1' else
       q_unsigned when (((a_sign xor b_sign) and is_signed) = '0') else
       std_logic_vector(-signed(q_unsigned));
end architecture behavioral;
