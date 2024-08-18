-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;

--! @brief
--!	CSD Arithmetic Logic Unit (CSD ALU).
entity csd_alu is
	port(
        y         : in  std_logic_vector(31 downto 0); --! Input operand.
		xs,xd     : in  std_logic_vector(32 downto 0); --! Input operand.
        ys,yd     : in  std_logic_vector(32 downto 0); --! Input operand.
		P_result  : out std_logic_vector(31 downto 0); --! Operation result.
        N_result  : out std_logic_vector(31 downto 0); --! Operation result
        W1 : out std_logic_vector(83 downto 0);
		W2 : out std_logic_vector(83 downto 0);
		W3 : out std_logic_vector(83 downto 0);
		W4 : out std_logic_vector(83 downto 0);
		Lpp: out std_logic_vector(67 downto 0);
		operation : in alu_operation                   --! Operation type.
	);
end entity csd_alu;

--! @brief Behavioural description of the ALU.
architecture behaviour of csd_alu is

constant GND : std_logic := '0';

signal TX,TY: std_logic_vector(65 downto 0);
signal AR,SR,TR: std_logic_vector(63 downto 0);
signal op: std_logic_vector(1 downto 0);

begin    
    GENERATE0: for i in 0 to 32 generate
        TX((2*i)+1)<= xd(i);
        TX(2*i) <= xs(i);
    end generate GENERATE0;
    
    GENERATE1: for i in 0 to 32 generate
       TY((2*i)+1)<= yd(i);
       TY(2*i) <= ys(i);
     end generate GENERATE1;
   
    mul_stg2: entity work.mul_stg2(Arch_32bit) port map(Xi=>TX, Yi=>TY, W1=>W1, W2=>W2, W3=>W3, W4=>W4, Lpp=>Lpp);
    Add: entity work.CFSD_Adder(Arch_32bit) port map(Xi=>TX(63 downto 0), Yi=>TY(63 downto 0), Ci_Plus=>GND, Ci_Minus=>GND, Sum(65 downto 64)=>op, Sum(63 downto 0)=>AR);
    Sub: entity work.BFSD_Sub(Arch_32bit) port map(Xi=>TX(63 downto 0), Yi=>TY(63 downto 0), Ci_Plus=>GND, Ci_Minus=>GND, Sub=>SR);
    
	calculate_TR: process(operation,AR, SR)
	begin
		case operation is
			when ALU_ADD => TR <= AR;
			when ALU_SUB => TR <= SR;
			when others => TR <= (others => '0');
		end case;
	end process calculate_TR;
	
    GENERATE_FOR: for i in 0 to 31 generate
        P_result(i)<= TR((2*i)+1);
        N_result(i)<= not(TR(2*i));
    end generate GENERATE_FOR;

end architecture behaviour;

