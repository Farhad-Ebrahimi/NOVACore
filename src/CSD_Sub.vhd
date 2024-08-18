-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

--___________________________ Scalable Carry Free Signed Digit Subtructor ____________________________

library ieee; 
use ieee.std_logic_1164.all;  

ENTITY BFSD_Sub IS                     
generic (Gen_var: integer:=31; constant MSB : integer := 63);

PORT(Xi,Yi :IN std_logic_vector(MSB downto 0);
     Ci_Plus,Ci_Minus : IN std_logic;
	 Sub :OUT std_logic_vector (MSB downto 0));
END BFSD_Sub;

ARCHITECTURE Arch_32bit OF BFSD_Sub IS

 component Compressor_422 is
    port
    (
      X_Plus     : in std_logic;
      X_Minus    : in std_logic;
      Y_Plus     : in std_logic;
      Y_Minus    : in std_logic;
      Ci_Plus    : in std_logic;
      Ci_Minus   : in std_logic;
      Cout_Plus  : out std_logic;
      Cout_Minus : out std_logic;
      Si         : out std_logic_vector (1 downto 0));
  end component;

  signal C, D : std_logic_vector (MSB downto 0) := (others => '0');
BEGIN

 UUT: entity work.Compressor_422(GC422AS) port map (X_Plus => Xi(0) , X_Minus => Xi(1) , Y_Plus => Yi(1) , Y_Minus => Yi(0) , Ci_Plus => '0'  , Ci_Minus => '0', Co_Plus=>C(0) , Co_Minus=>C(1) , Si( 1 downto 0)=>D( 1  downto 0  ));
  
Generate_Cmp: for i in 1 to Gen_var generate
	UUT0: entity work.Compressor_422(GC422AS) port map (X_Plus=>Xi(2*i) ,X_Minus =>Xi((2*i)+1) ,Y_Plus => Yi((2*i)+1) ,Y_Minus => Yi(2*i) ,Ci_Plus => C(2*(i-1))  ,Ci_Minus =>C((2*(i-1))+1),Co_Plus=>C(2*i) ,Co_Minus=>C((2*i)+1) ,Si=>D((2*i)+1 downto (2*i)));
 end generate Generate_Cmp; 
 
	Sub<= D ;
 
END Arch_32bit; 
 
