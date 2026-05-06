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

    ---7 => x"A03216D3",

  constant rom_memory : rom_type := (
    0  => x"00000097",   1  => x"04008093",   2  => x"30509073",   3  => x"00000097",
    4  => x"0ec08093",   5  => x"00000117",   6  => x"0e410113",   7  => x"00208763",
    8  => x"0000a023",   9  => x"9de30091",   10 => x"0117fe20",   11 => x"01130008",
    12 => x"0097fd61",   13 => x"80e70000",   14 => x"00730c00",   15 => x"bff51050",
    16 => x"f8410113",   17 => x"c20ac006",   18 => x"c612c40e",   19 => x"ca1ac816",
    20 => x"ce22cc1e",   21 => x"d22ad026",   22 => x"d632d42e",   23 => x"da3ad836",
    24 => x"de42dc3e",   25 => x"c2cac0c6",   26 => x"c6d2c4ce",   27 => x"cadac8d6",
    28 => x"cee2ccde",   29 => x"d2ead0e6",   30 => x"d6f2d4ee",   31 => x"dafad8f6",
    32 => x"2573dcfe",   33 => x"25f33420",   34 => x"860a3410",   35 => x"00000097",
    36 => x"04c080e7",   37 => x"41a24082",   38 => x"42c24232",   39 => x"43e24352",
    40 => x"54824472",   41 => x"55a25512",   42 => x"56c25632",   43 => x"57e25752",
    44 => x"48865872",   45 => x"49a64916",   46 => x"4ac64a36",   47 => x"4be64b56",
    48 => x"5c864c76",   49 => x"5da65d16",   50 => x"5ec65e36",   51 => x"5fe65f56",
    52 => x"07c10113",   53 => x"30200073",   54 => x"800007b7",   55 => x"8d7d07fd",
    56 => x"800007b7",   57 => x"156307c1",   58 => x"278300f5",   59 => x"90020000",
    60 => x"45018082",   61 => x"00008082",
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