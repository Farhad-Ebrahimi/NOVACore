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
   0  => x"002081d3",  -- Test 1: FADD.S f3, f1, f2 (Pi + e)
   1  => x"08208253",  -- Test 2: FSUB.S f4, f1, f2 (Pi - e)
   2  => x"102082d3",  -- Test 3: FMUL.S f5, f1, f2 (Pi * e)
   3  => x"18208353",  -- Test 4: FDIV.S f6, f1, f2 (Pi / e)
   4  => x"188384d3",  -- Test 5: FDIV.S f9, f7, f8 (1.0 / 0.0 = Inf)
   5  => x"10b50653",  -- Test 6: FMUL.S f12, f10, f11 (1e30 * 1e-30)
   6  => x"00a506d3",  -- Test 7: FADD.S f13, f10, f10 (1e30 + 1e30)
   7  => x"10708853",  -- Test 8: FMUL.S f16, f1, f7 (Pi * 1.0)
   8  => x"001788d3",  -- Test 9: FADD.S f17, f15, f1 (NaN + Pi)
   9  => x"18108953",  -- Test 10: FDIV.S f18, f1, f1 (Pi / Pi = 1.0)
   10 => x"088409d3",  -- Test 11: FSUB.S f19, f8, f8 (0 - 0)
   11 => x"00e38a53",  -- Test 12: FADD.S f20, f7, f14 (1.0 + Inf)
   12 => x"18110ad3",  -- Test 13: FDIV.S f21, f2, f1 (e / Pi)
   13 => x"10178b53",  -- Test 14: FMUL.S f22, f15, f1 (NaN * Pi)
   14 => x"18178bd3",  -- Test 15: FDIV.S f23, f15, f1 (NaN / Pi)
   15 => x"18138c53",  -- Test 16: FDIV.S f24, f1, f7 (Pi / 1.0)
   16 => x"00138cd3",  -- Test 17: FADD.S f25, f7, f1 (1.0 + Pi)
   17 => x"18238d53",  -- Test 18: FDIV.S f26, f7, f2 (1.0 / e)
   18 => x"FFF00013",  -- End Marker
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