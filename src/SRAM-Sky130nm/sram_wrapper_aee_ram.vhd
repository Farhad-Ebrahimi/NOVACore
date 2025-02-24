library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main_memory_wrapper is
    port (
        clk      : in std_logic;
        csb      : in std_logic;
        web      : in std_logic;
        stb      : in std_logic;
        wmask    : in std_logic_vector(3 downto 0);
        addr     : in std_logic_vector(11 downto 0); 
        din      : in std_logic_vector(31 downto 0);
        dout     : out std_logic_vector(31 downto 0);
        ack_out : out std_logic
    );
end entity main_memory_wrapper;

architecture rtl of main_memory_wrapper is

    signal sram_select : std_logic_vector(1 downto 0);  
    signal web_intermediate : std_logic;
    signal csb0_intermediate : std_logic;
    signal csb1_intermediate : std_logic;
    signal csb2_intermediate : std_logic;
    signal csb3_intermediate : std_logic;
    signal sram_addr   : std_logic_vector(7 downto 0); 
    signal dout_sram0   : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram1   : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram2   : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram3   : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram_blocks0 : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram_blocks1 : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram_blocks2 : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_sram_blocks3 : std_logic_vector(31 downto 0) := (others => '0');

        component sky130_sram_1kbyte_1rw1r_32x256_8 is
        port 
        (
            clk0: in std_logic;
            csb0: in std_logic;
            web0: in std_logic;
            wmask0 : in std_logic_vector(3 downto 0);
            addr0 : in std_logic_vector(7 downto 0);
            din0 : in std_logic_vector (31 downto 0);
            dout0 :out std_logic_vector (31 downto 0);
            clk1 : in std_logic;
            csb1 : in std_logic;
            addr1 : in std_logic_vector (7 downto 0);
            dout1 : out std_logic_vector (31 downto 0)
        );
    end component;

begin

    sram_select <= addr(11 downto 10);
    sram_addr   <= addr(9 downto 2);

    ack_out <= not csb; 
    web_intermediate <= not web;

    csb0_intermediate <= '0' when (csb = '1' and stb = '1' and (sram_select = "00")) else '1';
    csb1_intermediate <= '0' when (csb = '1' and stb = '1' and (sram_select = "01")) else '1';
    csb2_intermediate <= '0' when (csb = '1' and stb = '1' and (sram_select = "10")) else '1';
    csb3_intermediate <= '0' when (csb = '1' and stb = '1' and (sram_select = "11")) else '1';

    sram_0:  sky130_sram_1kbyte_1rw1r_32x256_8
        port map (
            clk0   => clk,
            csb0   => csb0_intermediate,
            web0   => web_intermediate,
            wmask0 => wmask,
            addr0  => sram_addr,
            din0   => din,
            dout0  => dout_sram_blocks0(31 downto 0),
            clk1   => '1',
            csb1   => '1',
            addr1  => (others=>'0'),
            dout1  => dout_sram0
        );

    sram_1:  sky130_sram_1kbyte_1rw1r_32x256_8
        port map (
            clk0   => clk,
            csb0   => csb1_intermediate,
            web0   => web_intermediate,
            wmask0 => wmask,
            addr0  => sram_addr,
            din0   => din,
            dout0  => dout_sram_blocks1(31 downto 0),
            clk1   => '1',
            csb1   => '1',
            addr1  => (others=>'0'),
            dout1  => dout_sram1
        );

    sram_2:  sky130_sram_1kbyte_1rw1r_32x256_8
        port map (
            clk0   => clk,
            csb0   => csb2_intermediate,
            web0   => web_intermediate,
            wmask0 => wmask,
            addr0  => sram_addr,
            din0   => din,
            dout0  => dout_sram_blocks2(31 downto 0),
            clk1   => '1',
            csb1   => '1',
            addr1  => (others=>'0'),
            dout1  => dout_sram2
        );

    sram_3:  sky130_sram_1kbyte_1rw1r_32x256_8
        port map (
            clk0   => clk,
            csb0   => csb3_intermediate,
            web0   => web_intermediate,
            wmask0 => wmask,
            addr0  => sram_addr,
            din0   => din,
            dout0  => dout_sram_blocks3(31 downto 0),
            clk1   => '1',
            csb1   => '1',
            addr1  => (others=>'0'),
            dout1  => dout_sram3
        );

    dout <= dout_sram_blocks0 when sram_select = "00" else
            dout_sram_blocks1 when sram_select = "01" else
            dout_sram_blocks2 when sram_select = "10" else
            dout_sram_blocks3;

end architecture rtl;
