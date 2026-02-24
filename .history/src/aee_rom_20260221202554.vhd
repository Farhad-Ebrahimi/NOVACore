-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsbl_rom is
  port (
    clka : in std_logic;
    addra : in std_logic_vector(7 downto 0);
    douta : out std_logic_vector(31 downto 0)
  );
end fsbl_rom;

architecture rtl of fsbl_rom is

  type rom_type is array(0 to 255) of std_logic_vector(31 downto 0);

  constant rom_memory : rom_type := (
      0 => x"00000117",   1 => x"20010113",   2 => x"400002b7",   3 => x"00512023",
      4 => x"404002b7",   5 => x"00512223",   6 => x"00012007",   7 => x"00412087",
      8 => x"00107153",   9 => x"081071d3",  10 => x"10107253",  11 => x"181072d3",
     12 => x"00212427",  13 => x"00312627",  14 => x"00412827",  15 => x"00512a27",
     others => x"00000000"
  );



begin

  process (clka)
  begin
    if rising_edge(clka) then
      douta <= rom_memory(to_integer(unsigned(addra)));
    end if;
  end process;

end rtl;