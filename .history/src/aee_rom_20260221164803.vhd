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
  0  => x"bd010113",  -- add sp, sp, -1072
  1  => x"42812623",  -- sw s0, 1068(sp)
  2  => x"43010413",  -- add s0, sp, 1072
  3  => x"404917b7",  -- lui a5, 0x40491
  4  => x"fda78793",  -- add a5, a5, -38
  5  => x"c6f42823",  -- sw a5, -912(s0)
  6  => x"402e07b7",  -- lui a5, 0x402e0
  7  => x"84d78793",  -- add a5, a5, -1971
  8  => x"c6f42a23",  -- sw a5, -908(s0)
  9  => x"bf040793",  -- add a5, s0, -1040
  10 => x"08078793",  -- add a5, a5, 128
  11 => x"0007a787",  -- flw fa5, 0(a5)
  12 => x"bef42627",  -- fsw fa5, -1044(s0)
  13 => x"bf040793",  -- add a5, s0, -1040
  14 => x"08478793",  -- add a5, a5, 132
  15 => x"0007a787",  -- flw fa5, 0(a5)
  16 => x"bef42427",  -- fsw fa5, -1048(s0)
  17 => x"bec42707",  -- flw fa4, -1044(s0)
  18 => x"be842787",  -- flw fa5, -1048(s0)
  19 => x"00f777d3",  -- fadd.s fa5, fa4, fa5
  20 => x"bef42227",  -- fsw fa5, -1052(s0)
  21 => x"bec42707",  -- flw fa4, -1044(s0)
  22 => x"be842787",  -- flw fa5, -1048(s0)
  23 => x"08f777d3",  -- fsub.s fa5, fa4, fa5
  24 => x"bef42027",  -- fsw fa5, -1056(s0)
  25 => x"bec42707",  -- flw fa4, -1044(s0)
  26 => x"be842787",  -- flw fa5, -1048(s0)
  27 => x"10f777d3",  -- fmul.s fa5, fa4, fa5
  28 => x"bcf42e27",  -- fsw fa5, -1060(s0)
  29 => x"bec42707",  -- flw fa4, -1044(s0)
  30 => x"be842787",  -- flw fa5, -1048(s0)
  31 => x"18f777d3",  -- fdiv.s fa5, fa4, fa5
  32 => x"bcf42c27",  -- fsw fa5, -1064(s0)
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