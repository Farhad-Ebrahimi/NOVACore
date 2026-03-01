-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main_memory_wrapper is
    generic (
        constant NUM_WMASKS : integer := 4;
        constant DATA_WIDTH : integer := 32;
        constant ADDR_WIDTH : integer := 9
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        csb : in std_logic;
        web : in std_logic;
        wmask : in std_logic_vector(NUM_WMASKS - 1 downto 0);
        addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity main_memory_wrapper;

architecture rtl of main_memory_wrapper is

    signal web_n : std_logic;
    signal csb_n : std_logic;

    signal sram_addr : std_logic_vector(ADDR_WIDTH - 3 downto 0);
    signal data_mask : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    signal dout_port0 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_port1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    
    component sky130_sram_2kbyte_1rw1r_32x512_8 is
        generic (
        ADDR_WIDTH : integer := 9
        );
        port (
            clk0 : in std_logic;
            csb0 : in std_logic;
            web0 : in std_logic;
            wmask0 : in std_logic_vector(NUM_WMASKS - 1 downto 0);
            addr0 : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            din0 : in std_logic_vector (DATA_WIDTH - 1 downto 0);
            dout0 : out std_logic_vector (DATA_WIDTH - 1 downto 0);
            clk1 : in std_logic;
            csb1 : in std_logic;
            addr1 : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
            dout1 : out std_logic_vector (DATA_WIDTH - 1 downto 0)
        );
    end component;

begin

    web_n <= not web;
    csb_n <= not csb;
    
    sram_addr <= addr(ADDR_WIDTH - 1 downto 2);
    
    gen_byte_mask : for i in 0 to 3 generate
        data_mask(8 * (i + 1) - 1 downto 8 * i) <= (others => wmask(i));
    end generate;

    dout <= (dout_port0 and data_mask) when csb_n = '0' else (others=> '0');
        
    memory_inst : sky130_sram_2kbyte_1rw1r_32x512_8
    generic map (
        ADDR_WIDTH => ADDR_WIDTH - 2
    )
    port map(
        clk0 => clk,
        csb0 => csb_n,
        web0 => web_n,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_port0,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_port1
    );
    
end architecture rtl;