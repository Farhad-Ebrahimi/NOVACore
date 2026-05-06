-- Generic Ternary Adder

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ternary_adder is
  generic (
        N: integer
  );

  port (
    a_pos,   a_neg   : in std_logic_vector(N - 1 downto 0);
    b_pos,   b_neg   : in std_logic_vector(N - 1 downto 0);
    cin_pos, cin_neg : in std_logic;
    s_pos,   s_neg   : out std_logic_vector(N downto 0)
  );
end entity ternary_adder;

architecture behavioral of ternary_adder is
  signal x_in : std_logic_vector(2 * N - 1 downto 0);
  signal y_in : std_logic_vector(2 * N - 1 downto 0);
  signal sum_out : std_logic_vector(2 * N + 1 downto 0);

begin
  generate_x_in: for i in 0 to N - 1 generate
    x_in(2 * i + 1) <= a_pos(i);
    x_in(2 * i) <= a_neg(i);
  end generate generate_x_in;

  generate_y_in: for i in 0 to N - 1 generate
    y_in(2 * i + 1) <= b_pos(i);
    y_in(2 * i) <= b_neg(i);
  end generate generate_y_in;

  cfsd_adder: entity work.CFSD_Adder
    generic map (
      Gen_var => N - 1,
      MSB => 2 * N - 1
    )

    port map (
      Xi => x_in,
      Yi => y_in,
      Ci_Plus => cin_pos,
      Ci_Minus => cin_neg,
      Sum => sum_out
    );

  generate_s: for i in 0 to N generate
    s_pos(i) <= sum_out(2 * i + 1);
    s_neg(i) <= sum_out(2 * i);
  end generate generate_s;
end architecture behavioral;
