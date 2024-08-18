-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_stg3 is
    Port (
        W1: in std_logic_vector(83 downto 0);
        W2: in std_logic_vector(83 downto 0); 
        W3: in std_logic_vector(83 downto 0); 
        W4: in std_logic_vector(83 downto 0); 
        Lpp : in std_logic_vector(67 downto 0);
        Pos_mul:out std_logic_vector(63 downto 0);
        Neg_mul : out std_logic_vector(63 downto 0)
    );
end entity mul_stg3;

architecture behaviour of mul_stg3 is

  signal X1, X2, X3, X4 : std_logic_vector(99 downto 0);
  
  signal Y1, Y2 : std_logic_vector(101 downto 0);
  signal Z1, Z2 : std_logic_vector(133 downto 0);
  signal prd_L, prd_R, PO : std_logic_vector(131 downto 0);
  
  signal opn_L : std_logic_vector(1 downto 0);
  signal opn_R : std_logic_vector(3 downto 0);
  
begin

------------------------> Partial Products Addition: Tree structure  stage 3 <------------------------
   X1 <= x"0000" & W1;
   X2 <= W2 & x"0000";
   
   X3 <= x"0000" & W3;
   X4 <= W4 & x"0000";
   
   Add_L3_0 : entity work.CFSD_Adder generic
     map (Gen_var => 49, MSB => 99) port
     map (Xi => X1, Yi => X2, Ci_Plus => '0', Ci_Minus => '0', Sum => Y1);
   Add_L3_1 : entity work.CFSD_Adder generic
     map (Gen_var => 49, MSB => 99) port
     map (Xi => X3, Yi => X4, Ci_Plus => '0', Ci_Minus => '0', Sum => Y2);
   ------------------------> Partial Products Addition: Tree structure  stage 4 <------------------------
   
   Z1 <= x"00000000" & Y1;
   Z2 <= Y2 & x"00000000";
   
   Add_L4_0 : entity work.CFSD_Adder generic
     map (Gen_var => 66, MSB => 133) port
     map (Xi => Z1, Yi => Z2, Ci_Plus => '0', Ci_Minus => '0', Sum(135 downto 132) => opn_R, Sum(131 downto 0) =>prd_R);
     
     prd_L <= Lpp & x"0000000000000000";
     
     Add_L5_0 : entity work.CFSD_Adder generic
     map (Gen_var => 65, MSB => 131) port
     map (Xi => prd_R, Yi => prd_L, Ci_Plus => '0', Ci_Minus => '0', Sum(133 downto 132) => opn_L, Sum(131 downto 0) => PO);
     
     GENERATE1: for i in 0 to 63 generate
       Pos_mul(i) <= PO(2*i+1);
       Neg_mul(i) <= not PO(2*i);
     end generate GENERATE1;
     
end architecture behaviour;
     
