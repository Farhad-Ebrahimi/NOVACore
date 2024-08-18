-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

--___________________________ Standard Full Adder Cell ____________________________

library ieee; 
 use ieee.std_logic_1164.all;  
 entity SFAC is  
   port( 
  X1, X2, Cin : in std_logic;  
  S, Cout : out std_logic
  );  
 end SFAC;  
 architecture GSFAC of SFAC is  
 signal IMS, a2, a3: std_logic;  
 begin  
   IMS <= X1 xor X2;  
   a2 <= X1 and X2;  
   a3 <= IMS and Cin;  
   Cout <= a2 or a3;  
   S <= IMS xor Cin;  
 end GSFAC;  
--___________________________ 4:2 Compressor Including SFAC ____________________________

library ieee; 
use ieee.std_logic_1164.all;  

ENTITY Compressor_422 IS                     

PORT(X_Plus,X_Minus,Y_Plus,Y_Minus,Ci_Plus,Ci_Minus : IN std_logic;
	 Co_Plus,Co_Minus :OUT std_logic;
	 Si :OUT std_logic_vector (1 downto 0));

END Compressor_422;

ARCHITECTURE GC422AS OF Compressor_422 IS

component SFAC is
	port( X1, X2, Cin : in std_logic; S, Cout : out std_logic);
end component;

Signal IMS, A1 ,A2,A3 : std_logic;

  BEGIN
   
   A2 <= not(X_Minus);
   A3 <= not(Y_Minus);
   
   UUT1: entity work.SFAC(GSFAC)port map(X1 => X_Plus, X2 => A2, Cin => Y_Plus, S => IMS, Cout => Co_Plus);
   UUT2: entity work.SFAC(GSFAC)port map(X1 => IMS, X2 => A3 , Cin => Ci_Plus, S => Si(0), Cout => A1);
   
   Si(1)<=Ci_Minus;
   Co_Minus<= not A1;
  
END GC422AS;

-------------------------------------------------> Scalable Carry Free Signed Digit Adder_Subtractor<-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity CFSD_Adder is
  generic
  (
    Gen_var      : integer := 31;
    constant MSB : integer := 63);
  port
  (
    Xi       : in std_logic_vector(MSB downto 0);
    Yi       : in std_logic_vector(MSB downto 0);
    Ci_Plus  : in std_logic;
    Ci_Minus : in std_logic;
    Sum      : out std_logic_vector (MSB + 2 downto 0));
end CFSD_Adder;

architecture Arch_32bit of CFSD_Adder is
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
begin

  UUT : entity work.Compressor_422(GC422AS) port map
    (X_Plus => Xi(0), X_Minus => Xi(1), Y_Plus => Yi(0), Y_Minus => Yi(1), Ci_Plus => '0', Ci_Minus => '0', Co_Plus => C(0), Co_Minus => C(1), Si => D(1 downto 0));
  Generate_Cmp : for i in 1 to Gen_var generate
    UUT0 : entity work.Compressor_422(GC422AS) port
      map (X_Plus => Xi(2 * i), X_Minus => Xi((2 * i) + 1), Y_Plus => Yi(2 * i), Y_Minus => Yi((2 * i) + 1), Ci_Plus => C(2 * (i - 1)), Ci_Minus => C((2 * (i - 1)) + 1), Co_Plus => C(2 * i), Co_Minus => C((2 * i) + 1), Si => D((2 * i) + 1 downto (2 * i)));
  end generate Generate_Cmp;

  Sum <= (C(MSB downto MSB - 1) & D); --output: 66 bit

end Arch_32bit;


