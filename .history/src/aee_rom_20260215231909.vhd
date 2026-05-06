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
      0 => x"ff010113",   -- addi sp, sp, -16
      1 => x"00812623",   -- sw s0, 12(sp)
      2 => x"01010413",   -- addi s0, sp, 16
      3 => x"000017b7",   -- lui a5, 0x1
      4 => x"0707a707",   -- flw fa4, 112(a5)
      5 => x"000017b7",   -- lui a5, 0x1
      6 => x"0747a787",   -- flw fa5, 116(a5)
      7 => x"00f777d3",   -- fadd.s fa5, fa4, fa5
      8 => x"80f1a427",   -- fsw fa5, -2040(gp)
      9 => x"000017b7",   -- lui a5, 0x1
     10 => x"0707a707",   -- flw fa4, 112(a5)
     11 => x"000017b7",   -- lui a5, 0x1
     12 => x"0747a787",   -- flw fa5, 116(a5)
     13 => x"08f777d3",   -- fsub.s fa5, fa4, fa5
     14 => x"80f1a627",   -- fsw fa5, -2036(gp)
     15 => x"000017b7",   -- lui a5, 0x1
     16 => x"0707a707",   -- flw fa4, 112(a5)
     17 => x"000017b7",   -- lui a5, 0x1
     18 => x"0747a787",   -- flw fa5, 116(a5)
     19 => x"10f777d3",   -- fmul.s fa5, fa4, fa5
     20 => x"80f1a827",   -- fsw fa5, -2032(gp)
     21 => x"000017b7",   -- lui a5, 0x1
     22 => x"0707a707",   -- flw fa4, 112(a5)
     23 => x"000017b7",   -- lui a5, 0x1
     24 => x"0747a787",   -- flw fa5, 116(a5)
     25 => x"18f777d3",   -- fdiv.s fa5, fa4, fa5
     26 => x"18f767d3",   -- fdiv.s fa5, fa4, fa5
     27 => x"80f1aa27",   -- fsw fa5, -2028(gp)
     28 => x"0000006f",   -- j 0x6c (loop forever)
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