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
    0 => x"3f800000",   1 => x"41200000",   2 => x"3f000000",   3 => x"c0079553",
    4 => x"00112e23",   5 => x"00060493",   6 => x"d0057753",   7 => x"08e7f7d3",
    8 => x"f0000753",   9 => x"a0e797d3",   10 => x"00078463",  11 => x"20f797d3",
    12 => x"00000613",  13 => x"00f12627",  14 => x"00b12423",  15 => x"00000097",
    16 => x"000080e7",  17 => x"06048863",  18 => x"00812583",  19 => x"02e00713",
    20 => x"00c12787",  21 => x"00a587b3",  22 => x"00e78023",  23 => x"00000737",
    24 => x"00072707",  25 => x"00000737",  26 => x"00072687",  27 => x"00000793",
    28 => x"0297cc63",  29 => x"10e7f7d3",  30 => x"000007b7",  31 => x"0007a707",
    32 => x"00150513",  33 => x"01c12083",  34 => x"00e7f7d3",  35 => x"00048613",
    36 => x"00a585b3",  37 => x"01812483",  38 => x"c0079553",  39 => x"02010113",
    40 => x"00000317",  41 => x"00030067",  42 => x"10d77753",  43 => x"00178793",
    44 => x"fc1ff06f",  45 => x"01c12083",  46 => x"01812483",  47 => x"f79ff06f",
    
    -- Padding remainder with zeros
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