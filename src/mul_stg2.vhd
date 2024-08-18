-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>


library IEEE;
use IEEE.std_logic_1164.all;

entity mul_stg2 is

  generic
    (constant MSB : integer := 65);
  port
  (
    Xi : in std_logic_vector(MSB downto 0);
    Yi : in std_logic_vector(MSB downto 0);
    W1 : out std_logic_vector(83 downto 0);
    W2 : out std_logic_vector(83 downto 0);
    W3 : out std_logic_vector(83 downto 0);
    W4 : out std_logic_vector(83 downto 0);
    Lpp: out std_logic_vector(67 downto 0)
  );
end mul_stg2;

architecture Arch_32bit of mul_stg2 is

  type t_Memory is array (15 downto 0) of std_logic_vector(67 downto 0);
  signal Fr_Mem, Sr_Mem, Tr_Mem : t_Memory;

  type p_Memory is array (15 downto 0) of std_logic_vector(71 downto 0);
  signal T : p_Memory;

  signal U1, U2, U3, U4, U5, U6, U7, U8 : std_logic_vector(73 downto 0);
  signal V1, V2, V3, V4, V5, V6, V7, V8 : std_logic_vector(81 downto 0);

begin

  ------------------------> Partial Products Generation <------------------------
  Gen1 : for i in 0 to 7 generate
    process (Xi, Yi)
    begin
      case Yi(4 * i + 1 downto 4 * i) is
        when "01" =>
          Fr_Mem(2 * i) <= "00" & not(Xi);
        when "10" =>
          Fr_Mem(2 * i) <= "00" & Xi;
        when others              =>
          Fr_Mem(2 * i) <= (others => '0');
      end case;

      case Yi(4 * i + 3 downto 4 * i + 2) is
        when "01" =>
          Fr_Mem(2 * i + 1) <= not(Xi) & "00";
        when "10" =>
          Fr_Mem(2 * i + 1) <= Xi & "00";
        when others                  =>
          Fr_Mem(2 * i + 1) <= (others => '0');
      end case;

      case Yi(4 * i + 33 downto 4 * i + 32) is
        when "01" =>
          Sr_Mem(2 * i) <= "00" & not(Xi);
        when "10" =>
          Sr_Mem(2 * i) <= "00" & Xi;
        when others              =>
          Sr_Mem(2 * i) <= (others => '0');
      end case;

      case Yi(4 * i + 35 downto 4 * i + 34) is
        when "01" =>
          Sr_Mem(2 * i + 1) <= not(Xi) & "00";
        when "10" =>
          Sr_Mem(2 * i + 1) <= Xi & "00";
        when others                  =>
          Sr_Mem(2 * i + 1) <= (others => '0');
      end case;
    end process;
  end generate Gen1;
  
  process (Xi, Yi)
    begin
        case Yi(65 downto 64) is
           when "01" =>
               Lpp <= "00" & not(Xi);
           when "10" =>
               Lpp <= "00" & Xi;
           when others =>
               Lpp <= (others => '0');
        end case;
    end process;

  Gen3 : for i in 0 to 7 generate
    Tr_Mem(i)     <= Fr_Mem(2 * i + 1) or Fr_Mem(2 * i);
    Tr_Mem(i + 8) <= Sr_Mem(2 * i + 1) or Sr_Mem(2 * i);
  end generate Gen3;
  ------------------------> Partial Products Addition: Tree structure  stage 1 <------------------------

  Gen4 : for i in 0 to 7 generate
    T(2 * i)     <= x"0" & Tr_Mem(2 * i);
    T(2 * i + 1) <= Tr_Mem(2 * i + 1) & x"0";
  end generate Gen4;

    Add_L1_0 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port map
    (Xi => T(0), Yi => T(1), Ci_Plus => '0', Ci_Minus => '0', Sum => U1);
  Add_L1_1 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(2), Yi => T(3), Ci_Plus => '0', Ci_Minus => '0', Sum => U2);
  Add_L1_2 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(4), Yi => T(5), Ci_Plus => '0', Ci_Minus => '0', Sum => U3);
  Add_L1_3 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(6), Yi => T(7), Ci_Plus => '0', Ci_Minus => '0', Sum => U4);
  Add_L1_4 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(8), Yi => T(9), Ci_Plus => '0', Ci_Minus => '0', Sum => U5);
  Add_L1_5 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(10), Yi => T(11), Ci_Plus => '0', Ci_Minus => '0', Sum => U6);
  Add_L1_6 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(12), Yi => T(13), Ci_Plus => '0', Ci_Minus => '0', Sum => U7);
  Add_L1_7 : entity work.CFSD_Adder generic
    map (Gen_var => 35, MSB => 71) port
    map (Xi => T(14), Yi => T(15), Ci_Plus => '0', Ci_Minus => '0', Sum => U8);

  ------------------------> Partial Products Addition: Tree structure stage 2 <------------------------

  V1 <= x"00" & U1;
  V2 <= U2 & x"00";

  V3 <= x"00" & U3;
  V4 <= U4 & x"00";

  V5 <= x"00" & U5;
  V6 <= U6 & x"00";

  V7 <= x"00" & U7;
  V8 <= U8 & x"00";

  Add_L2_0 : entity work.CFSD_Adder generic
    map (Gen_var => 40, MSB => 81) port
    map (Xi => V1, Yi => V2, Ci_Plus => '0', Ci_Minus => '0', Sum => W1);
  Add_L2_1 : entity work.CFSD_Adder generic
    map (Gen_var => 40, MSB => 81) port
    map (Xi => V3, Yi => V4, Ci_Plus => '0', Ci_Minus => '0', Sum => W2);
  Add_L2_2 : entity work.CFSD_Adder generic
    map (Gen_var => 40, MSB => 81) port
    map (Xi => V5, Yi => V6, Ci_Plus => '0', Ci_Minus => '0', Sum => W3);
  Add_L2_3 : entity work.CFSD_Adder generic
    map (Gen_var => 40, MSB => 81) port
    map (Xi => V7, Yi => V8, Ci_Plus => '0', Ci_Minus => '0', Sum => W4);

end Arch_32bit;
