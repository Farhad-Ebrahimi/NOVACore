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
   0 => x"fd010113",  1 => x"02812623",  2 => x"03010413",  3 => x"400007b7",
   4 => x"fcf42a23",  5 => x"404007b7",  6 => x"fcf42823",  7 => x"fd440793",
   8 => x"0007a787",  9 => x"fef42627", 10 => x"fd040793", 11 => x"0007a787",
  12 => x"fef42427", 13 => x"fec42707", 14 => x"fe842787", 15 => x"00f777d3",
  16 => x"fef42227", 17 => x"fec42707", 18 => x"fe842787", 19 => x"08f777d3",
  20 => x"fef42027", 21 => x"fec42707", 22 => x"fe842787", 23 => x"10f777d3",
  24 => x"fcf42e27", 25 => x"fec42707", 26 => x"fe842787", 27 => x"18f777d3",
  28 => x"fcf42c27", 29 => x"00000793", 30 => x"00078513", 31 => x"02c12403",
  32 => x"03010113", 33 => x"00008067",
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