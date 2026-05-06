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
   0  => x"fd010113",  -- add sp, sp, -48
   1  => x"02812623",  -- sw s0, 44(sp)
   2  => x"03010413",  -- add s0, sp, 48
 -- 3  => x"08002787",  -- flw fa5, 128(zero)
 -- 4  => x"fef42627",  -- fsw fa5, -20(s0)
 -- 5  => x"08402787",  -- flw fa5, 132(zero)
 -- 6  => x"fef42427",  -- fsw fa5, -24(s0)
 -- 7  => x"fec42787",  -- flw fa5, -20(s0)
 -- 8  => x"fef42227",  -- fsw fa5, -28(s0)
 -- 9  => x"fe842787",  -- flw fa5, -24(s0)
 -- 10 => x"fef42027",  -- fsw fa5, -32(s0)
 -- 11 => x"fe442707",  -- flw fa4, -28(s0)
 -- 12 => x"fe042787",  -- flw fa5, -32(s0)
 -- 13 => x"00f777d3",  -- fadd.s fa5, fa4, fa5
 -- 14 => x"fcf42e27",  -- fsw fa5, -36(s0)
 -- 15 => x"fe442707",  -- flw fa4, -28(s0)
 -- 16 => x"fe042787",  -- flw fa5, -32(s0)
 -- 17 => x"08f777d3",  -- fsub.s fa5, fa4, fa5
 -- 18 => x"fcf42c27",  -- fsw fa5, -40(s0)
 -- 19 => x"fe442707",  -- flw fa4, -28(s0)
 -- 20 => x"fe042787",  -- flw fa5, -32(s0)
 -- 21 => x"10f777d3",  -- fmul.s fa5, fa4, fa5
 -- 22 => x"fcf42a27",  -- fsw fa5, -44(s0)
 -- 23 => x"fe442707",  -- flw fa4, -28(s0)
 -- 24 => x"fe042787",  -- flw fa5, -32(s0)
 -- 25 => x"18f777d3",  -- fdiv.s fa5, fa4, fa5
 -- 26 => x"fcf42827",  -- fsw fa5, -48(s0)
 -- 27 => x"00000793",  -- li a5, 0
 -- 28 => x"00078513",  -- mv a0, a5
 -- 29 => x"02c12403",  -- lw s0, 44(sp)
 -- 30 => x"03010113",  -- add sp, sp, 48
 -- 31 => x"00008067",  -- ret
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