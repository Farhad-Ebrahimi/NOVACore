library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_stg1 is
  port (
    a            : in std_logic_vector(31 downto 0);
    b            : in std_logic_vector(31 downto 0);
    is_signed    : in std_logic;
    a_sign       : out std_logic;
    b_sign       : out std_logic;
    a_norm       : out std_logic_vector(31 downto 0);
    b_norm       : out std_logic_vector(31 downto 0);
    shift_a      : out unsigned(4 downto 0);
    shift_b      : out unsigned(4 downto 0);
    div_by_zero  : out std_logic;
    div_overflow : out std_logic
  );
end entity divider_stg1;

architecture behavioral of divider_stg1 is
  signal a_abs        : std_logic_vector(31 downto 0);
  signal b_abs        : std_logic_vector(31 downto 0);

begin
  a_abs <= a when is_signed = '0' else std_logic_vector(abs(signed(a)));
  a_sign <= a(31);
  b_abs <= b when is_signed = '0' else std_logic_vector(abs(signed(b)));
  b_sign <= b(31);

  div_by_zero <= '1' when b = (31 downto 0 => '0') else '0';
  div_overflow <= '1' when (is_signed = '1' and a = x"80000000" and b = x"FFFFFFFF") else '0';

  normalizer_a: entity work.normalizer
    port map (
      x_in => a_abs,
      x_out => a_norm,
      shift => shift_a
    );

  normalizer_b: entity work.normalizer
    port map (
      x_in => b_abs,
      x_out => b_norm,
      shift => shift_b
    );
end architecture behavioral;
