-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

--___________________________ OAI Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity OAI is
  port (
    x : in std_logic_vector(2 downto 0);
    gk : out std_logic
  );
end OAI;

architecture GL of OAI is
begin
  gk <= x(2) and (x(1) or x(0));
end GL;
--___________________________ OAAI Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity OOAI is
  port (
    x : in std_logic_vector(3 downto 0);
    gk : out std_logic;
    pk : out std_logic
  );
end OOAI;

architecture GL of OOAI is
begin
  gk <= x(3) and (x(2) or x(1));
  pk <= x(2) or x(0);
end GL;

--___________________________ AOI Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity AOI is
  port (
    x : in std_logic_vector(2 downto 0);
    gh : out std_logic
  );
end AOI;

architecture GL of AOI is
begin
  gh <= x(2) or (x(1) and x(0));
end GL;
--___________________________ AAOI Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity AAOI is
  port (
    x : in std_logic_vector(3 downto 0);
    gh : out std_logic;
    ph : out std_logic
  );
end AAOI;

architecture GL of AAOI is
begin
  gh <= x(3) or (x(2) and x(1));
  ph <= x(2) and x(0);
end GL;

--___________________________ First CSD Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity First_CSD_Module is
  port (
    h2 : in std_logic;
    k2 : in std_logic;
    x : in std_logic_vector(1 downto 0);
    ys : out std_logic_vector(1 downto 0);
    yd : out std_logic_vector(1 downto 0)
  );
end First_CSD_Module;

architecture GL of First_CSD_Module is
  signal h1_bar, K1_bar : std_logic;
begin
  h1_bar <= x(1) nand x(0);
  K1_bar <= not (x(1));

  yd(0) <= x(0) and K1_bar;
  yd(1) <= h2 nor K1_bar;

  ys(0) <= not h1_bar;
  ys(1) <= k2 and h1_bar;
end GL;
--___________________________ 4-bit CSD Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity Four_bit_CSD_Module is
  port (
    hi : in std_logic;
    ki : in std_logic;
    hi4 : in std_logic;
    ki4 : in std_logic;
    xi : in std_logic_vector(2 downto 0);
    ys : out std_logic_vector(3 downto 0);
    yd : out std_logic_vector(3 downto 0)
  );
end Four_bit_CSD_Module;

architecture GL of Four_bit_CSD_Module is

  signal hi1_bar, Ki1_bar : std_logic;
  signal hi3_bar, Ki3_bar : std_logic;
  signal hi2, Ki2 : std_logic;
  signal before_hi2, before_Ki2 : std_logic;

begin

  before_Ki2 <= xi(0) or ki;
  before_hi2 <= xi(0) and hi;

  hi2 <= xi(1) or before_hi2;
  ki2 <= xi(1) and before_ki2;

  hi1_bar <= hi nand xi(0);
  Ki1_bar <= ki nor xi(0);

  hi3_bar <= hi2 nand xi(2);
  Ki3_bar <= ki2 nor xi(2);

  yd(0) <= hi and Ki1_bar;
  yd(1) <= hi2 nor Ki1_bar;
  yd(2) <= hi2 and Ki3_bar;
  yd(3) <= hi4 nor Ki3_bar;

  ys(0) <= ki nor hi1_bar;
  ys(1) <= ki2 and hi1_bar;
  ys(2) <= ki2 nor hi3_bar;
  ys(3) <= ki4 and hi3_bar;

end GL;

--___________________________ Last CSD Module ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity Last_CSD_Module is
  port (
    xn_minus_1 : in std_logic;
    kn_minus_2 : in std_logic;
    hn_minus_2 : in std_logic;
    ys : out std_logic_vector(1 downto 0);
    yd : out std_logic_vector(1 downto 0)
  );
end Last_CSD_Module;

architecture GL of Last_CSD_Module is

  signal hn_minus_1_bar, kn_minus_1_bar : std_logic;

begin

  hn_minus_1_bar <= xn_minus_1 nand hn_minus_2;
  kn_minus_1_bar <= xn_minus_1 nor kn_minus_2;

  yd(0) <= hn_minus_2 and kn_minus_1_bar;
  yd(1) <= kn_minus_2 and hn_minus_1_bar;

  ys(0) <= kn_minus_2 nor hn_minus_1_bar;
  ys(1) <= hn_minus_2 nor kn_minus_1_bar;

end GL;

--___________________________ Binery to CSD Recoder--> Ruiz,2011 ____________________________

library ieee;
use ieee.std_logic_1164.all;

entity B2C is
  generic (MSB : integer := 31);
  port (
    x : in std_logic_vector(MSB downto 0);
    ys : out std_logic_vector(MSB downto 0);
    yd : out std_logic_vector(MSB downto 0)
  );
end B2C;

architecture GL of B2C is

  component First_CSD_Module is
    port (
      h2 : in std_logic;
      k2 : in std_logic;
      x : in std_logic_vector(1 downto 0);
      ys : out std_logic_vector(1 downto 0);
      yd : out std_logic_vector(1 downto 0)
    );
  end component;

  component Four_bit_CSD_Module is
    port (
      hi : in std_logic;
      ki : in std_logic;
      hi4 : in std_logic;
      ki4 : in std_logic;
      xi : in std_logic_vector(2 downto 0);
      ys : out std_logic_vector(3 downto 0);
      yd : out std_logic_vector(3 downto 0)
    );
  end component;

  component Last_CSD_Module is
    port (
      xn_minus_1 : in std_logic;
      kn_minus_2 : in std_logic;
      hn_minus_2 : in std_logic;
      ys : out std_logic_vector(1 downto 0);
      yd : out std_logic_vector(1 downto 0)
    );
  end component;

  signal h2, h6 : std_logic;
  signal h10, h14 : std_logic;
  signal h18, h22 : std_logic;
  signal h26, h30 : std_logic;
  signal k2, k6 : std_logic;
  signal k10, k14 : std_logic;
  signal k18, k22 : std_logic;
  signal k26, k30 : std_logic;
  signal ph, pk : std_logic_vector(6 downto 0);
  signal gh, gk : std_logic_vector(7 downto 0);
  signal L3_h, L3_k : std_logic_vector(8 downto 0);
  signal L2_h, L2_k : std_logic_vector(12 downto 0);

begin

  -- // H signal calculation

  AOI_L10 : entity work.AOI(GL) port map
    (x => x(2 downto 0), gh => gh(0));
  AAOI_L10 : entity work.AAOI(GL) port map (x => x(6 downto 3), gh => gh(1), ph => ph(0));
  AAOI_L11 : entity work.AAOI(GL) port map (x => x(10 downto 7), gh => gh(2), ph => ph(1));
  AAOI_L12 : entity work.AAOI(GL) port map (x => x(14 downto 11), gh => gh(3), ph => ph(2));
  AAOI_L13 : entity work.AAOI(GL) port map (x => x(18 downto 15), gh => gh(4), ph => ph(3));
  AAOI_L14 : entity work.AAOI(GL) port map (x => x(22 downto 19), gh => gh(5), ph => ph(4));
  AAOI_L15 : entity work.AAOI(GL) port map (x => x(26 downto 23), gh => gh(6), ph => ph(5));
  AAOI_L16 : entity work.AAOI(GL) port map (x => x(30 downto 27), gh => gh(7), ph => ph(6));

  h2 <= gh(0);

  AOI_L20 : entity work.AOI(GL) port map (x(2) => gh(1), x(1) => ph(0), x(0) => gh(0), gh => L2_h(0));                                   --L2_h(0)= gh(1) + ph(0) . gh(0)
  AAOI_L20 : entity work.AAOI(GL) port map (x(3) => gh(2), x(2) => ph(1), x(1) => gh(1), x(0) => ph(0), gh => L2_h(2), ph => L2_h(1));   --L2_h(2)= gh(2) + ph(1) . gh(1) / L2_h(1)= ph(1) . ph(0)
  AAOI_L21 : entity work.AAOI(GL) port map (x(3) => gh(3), x(2) => ph(2), x(1) => gh(2), x(0) => ph(1), gh => L2_h(4), ph => L2_h(3));   --L2_h(4)= gh(3) + ph(2) . gh(2) / L2_h(3)= ph(2) . ph(1)
  AAOI_L22 : entity work.AAOI(GL) port map (x(3) => gh(4), x(2) => ph(3), x(1) => gh(3), x(0) => ph(2), gh => L2_h(6), ph => L2_h(5));   --L2_h(6)= gh(4) + ph(3) . gh(3) / L2_h(5)= ph(3) . ph(2)
  AAOI_L23 : entity work.AAOI(GL) port map (x(3) => gh(5), x(2) => ph(4), x(1) => gh(4), x(0) => ph(3), gh => L2_h(8), ph => L2_h(7));   --L2_h(8)= gh(5) + ph(4) . gh(4) / L2_h(7)= ph(4) . ph(3)
  AAOI_L24 : entity work.AAOI(GL) port map (x(3) => gh(6), x(2) => ph(5), x(1) => gh(5), x(0) => ph(4), gh => L2_h(10), ph => L2_h(9));  --L2_h(10)= gh(6) + ph(5) . gh(5) / L2_h(9)= ph(5) . ph(4)
  AAOI_L25 : entity work.AAOI(GL) port map (x(3) => gh(7), x(2) => ph(6), x(1) => gh(6), x(0) => ph(5), gh => L2_h(12), ph => L2_h(11)); --L2_h(12)= gh(7) + ph(6) . gh(6) / L2_h(11)= ph(6) . ph(5)
  
  h6 <= L2_h(0);

  AOI_L30 : entity work.AOI(GL) port map (x(2) => gh(2), x(1) => ph(1), x(0) => L2_h(0), gh => h10); -- h10 = gh(2) + ph(1) . L2_h(0)
  AOI_L31 : entity work.AOI(GL) port map (x(2) => L2_h(4), x(1) => L2_h(3), x(0) => L2_h(0), gh => L3_h(0)); -- (gh(3)+ ph(2)gh(2)) + (ph(2) . ph(1) . (gh(1) + ph(0) . gh(0)))

  AAOI_L32 : entity work.AAOI(GL) port map (x(3) => L2_h(6), x(2) => L2_h(5), x(1) => L2_h(2), x(0) => L2_h(1), gh => L3_h(2), ph => L3_h(1));    --L3_h(2)= (gh(4) + ph(3) . gh(3)) + (ph(3) . ph(2). (gh(2) + ph(1) . gh(1)))/ L3_h(1)= ph(3) . ph(2) . ph(1) . ph(0)
  AAOI_L33 : entity work.AAOI(GL) port map (x(3) => L2_h(8), x(2) => L2_h(7), x(1) => L2_h(4), x(0) => L2_h(3), gh => L3_h(4), ph => L3_h(3));    --L3_h(4)= (gh(5) + ph(4) . gh(4)) + (ph(4) . ph(3). (gh(3) + ph(2) . gh(2)))/ L3_h(3)= ph(4) . ph(3) . ph(2) . ph(1)
  AAOI_L34 : entity work.AAOI(GL) port map (x(3) => L2_h(10), x(2) => L2_h(9), x(1) => L2_h(6), x(0) => L2_h(5), gh => L3_h(6), ph => L3_h(5));   --L3_h(6)= (gh(6) + ph(5) . gh(5)) + (ph(5) . ph(4). (gh(4) + ph(3) . gh(3)))/ L3_h(5)= ph(5) . ph(4) . ph(3) . ph(2)
  AAOI_L35 : entity work.AAOI(GL) port map (x(3) => L2_h(12), x(2) => L2_h(11), x(1) => L2_h(8), x(0) => L2_h(7), gh => L3_h(8), ph => L3_h(7));  --L3_h(8)= (gh(7) + ph(6) . gh(6)) + (ph(6) . ph(5). (gh(5) + ph(4) . gh(4)))/ L3_h(7)= ph(6) . ph(5) . ph(4) . ph(3)

  h14 <= L3_h(0);

  AOI_L40 : entity work.AOI(GL) port map (x(2) => L3_h(2), x(1) => L3_h(1), x(0) => gh(0), gh => h18);
  AOI_L41 : entity work.AOI(GL) port map (x(2) => L3_h(4), x(1) => L3_h(3), x(0) => L2_h(0), gh => h22);
  AOI_L42 : entity work.AOI(GL) port map (x(2) => L3_h(6), x(1) => L3_h(5), x(0) => h10, gh => h26);
  AOI_L43 : entity work.AOI(GL) port map (x(2) => L3_h(8), x(1) => L3_h(7), x(0) => L3_h(0), gh => h30);


  -- // K signal calculation

  gk(0) <= x(2) and x(1);
  OOAIL10 : entity work.OOAI(GL) port map (x => x(6 downto 3), gk => gk(1), pk => pk(0));
  OOAIL11 : entity work.OOAI(GL) port map (x => x(10 downto 7), gk => gk(2), pk => pk(1));
  OOAIL12 : entity work.OOAI(GL) port map (x => x(14 downto 11), gk => gk(3), pk => pk(2));
  OOAIL13 : entity work.OOAI(GL) port map (x => x(18 downto 15), gk => gk(4), pk => pk(3));
  OOAIL14 : entity work.OOAI(GL) port map (x => x(22 downto 19), gk => gk(5), pk => pk(4));
  OOAIL15 : entity work.OOAI(GL) port map (x => x(26 downto 23), gk => gk(6), pk => pk(5));
  OOAIL16 : entity work.OOAI(GL) port map (x => x(30 downto 27), gk => gk(7), pk => pk(6));

  OAI_L20 : entity work.OAI(GL) port map (x(2) => gk(1), x(1) => pk(0), x(0) => gk(0), gk => L2_k(0));
  OOAIL20 : entity work.OOAI(GL) port map (x(3) => gk(2), x(2) => pk(1), x(1) => gk(1), x(0) => pk(0), gk => L2_k(2), pk => L2_k(1));
  OOAIL21 : entity work.OOAI(GL) port map (x(3) => gk(3), x(2) => pk(2), x(1) => gk(2), x(0) => pk(1), gk => L2_k(4), pk => L2_k(3));
  OOAIL22 : entity work.OOAI(GL) port map (x(3) => gk(4), x(2) => pk(3), x(1) => gk(3), x(0) => pk(2), gk => L2_k(6), pk => L2_k(5));
  OOAIL23 : entity work.OOAI(GL) port map (x(3) => gk(5), x(2) => pk(4), x(1) => gk(4), x(0) => pk(3), gk => L2_k(8), pk => L2_k(7));
  OOAIL24 : entity work.OOAI(GL) port map (x(3) => gk(6), x(2) => pk(5), x(1) => gk(5), x(0) => pk(4), gk => L2_k(10), pk => L2_k(9));
  OOAIL25 : entity work.OOAI(GL) port map (x(3) => gk(7), x(2) => pk(6), x(1) => gk(6), x(0) => pk(5), gk => L2_k(12), pk => L2_k(11));

  k2 <= gk(0);
  k6 <= L2_k(0);

  OAI_L30 : entity work.OAI(GL) port map (x(2) => L2_k(2), x(1) => L2_k(1), x(0) => gk(0), gk => k10);
  OAI_L31 : entity work.OAI(GL) port map (x(2) => L2_k(4), x(1) => L2_k(3), x(0) => L2_k(0), gk => L3_k(0));
  OOAIL32 : entity work.OOAI(GL) port map (x(3) => L2_k(6), x(2) => L2_k(5), x(1) => L2_k(2), x(0) => L2_k(1), gk => L3_k(2), pk => L3_k(1));
  OOAIL33 : entity work.OOAI(GL) port map (x(3) => L2_k(8), x(2) => L2_k(7), x(1) => L2_k(4), x(0) => L2_k(3), gk => L3_k(4), pk => L3_k(3));
  OOAIL34 : entity work.OOAI(GL) port map (x(3) => L2_k(10), x(2) => L2_k(9), x(1) => L2_k(6), x(0) => L2_k(5), gk => L3_k(6), pk => L3_k(5));
  OOAIL35 : entity work.OOAI(GL) port map (x(3) => L2_k(12), x(2) => L2_k(11), x(1) => L2_k(8), x(0) => L2_k(7), gk => L3_k(8), pk => L3_k(7));

  k14 <= L3_k(0);
  OAI_L40 : entity work.OAI(GL) port map (x(2) => L3_k(2), x(1) => L3_k(1), x(0) => gk(0), gk => k18);
  OAI_L41 : entity work.OAI(GL) port map (x(2) => L3_k(4), x(1) => L3_k(3), x(0) => L2_k(0), gk => k22);
  OAI_L42 : entity work.OAI(GL) port map (x(2) => L3_k(6), x(1) => L3_k(5), x(0) => k10, gk => k26);
  OAI_L43 : entity work.OAI(GL) port map (x(2) => L3_k(8), x(1) => L3_k(7), x(0) => L3_k(0), gk => k30);

  -- // Final Stages

  First_CSD_Module_0 : entity work.First_CSD_Module(GL) port map (x => x(1 downto 0), h2 => h2, k2 => k2, ys => ys(1 downto 0), yd => yd(1 downto 0));
  Four_bit_CSD_Module_0 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(5 downto 3), hi => h2, ki => k2, hi4 => h6, ki4 => k6, ys => ys(5 downto 2), yd => yd(5 downto 2));
  Four_bit_CSD_Module_1 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(9 downto 7), hi => h6, ki => k6, hi4 => h10, ki4 => k10, ys => ys(9 downto 6), yd => yd(9 downto 6));
  Four_bit_CSD_Module_2 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(13 downto 11), hi => h10, ki => k10, hi4 => h14, ki4 => k14, ys => ys(13 downto 10), yd => yd(13 downto 10));
  Four_bit_CSD_Module_3 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(17 downto 15), hi => h14, ki => k14, hi4 => h18, ki4 => k18, ys => ys(17 downto 14), yd => yd(17 downto 14));
  Four_bit_CSD_Module_4 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(21 downto 19), hi => h18, ki => k18, hi4 => h22, ki4 => k22, ys => ys(21 downto 18), yd => yd(21 downto 18));
  Four_bit_CSD_Module_5 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(25 downto 23), hi => h22, ki => k22, hi4 => h26, ki4 => k26, ys => ys(25 downto 22), yd => yd(25 downto 22));
  Four_bit_CSD_Module_6 : entity work.Four_bit_CSD_Module(GL) port map (xi => x(29 downto 27), hi => h26, ki => k26, hi4 => h30, ki4 => k30, ys => ys(29 downto 26), yd => yd(29 downto 26));
  Last_CSD_Module_0 : entity work.Last_CSD_Module(GL) port map (xn_minus_1 => x(31), hn_minus_2 => h30, kn_minus_2 => k30, ys => ys(31 downto 30), yd => yd(31 downto 30));

end GL;
