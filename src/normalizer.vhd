library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity normalizer is
  port (
    x_in  : in  std_logic_vector(31 downto 0);
    x_out : out std_logic_vector(31 downto 0);
    shift : out unsigned(4 downto 0)
  );
end entity;

architecture rtl of normalizer is
begin
  process(x_in)
    variable shift_cnt : integer range 0 to 31;
  begin
    shift_cnt := 0;

    for i in 31 downto 0 loop
      if x_in(i) = '1' then
        shift_cnt := 31 - i;
        exit;
      end if;
    end loop;

    x_out <= std_logic_vector(shift_left(unsigned(x_in), shift_cnt));
    shift <= to_unsigned(shift_cnt, shift'length);
  end process;
end architecture;
