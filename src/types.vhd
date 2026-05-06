library ieee;
use ieee.std_logic_1164.all;

package types is
  type array_of_16_bits is array (natural range <>) of std_logic_vector(15 downto 0);
  type array_of_32_bits is array (natural range <>) of std_logic_vector(31 downto 0);
  type array_of_34_bits is array (natural range <>) of std_logic_vector(33 downto 0);
  type array_of_35_bits is array (natural range <>) of std_logic_vector(34 downto 0);
end package;
