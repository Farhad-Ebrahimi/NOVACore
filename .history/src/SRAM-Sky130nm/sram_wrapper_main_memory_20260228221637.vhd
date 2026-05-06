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

    -- Internal registers to stabilize inputs
    signal addr_reg  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal din_reg   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal web_reg   : std_logic;
    signal csb_reg   : std_logic;
    signal wmask_reg : std_logic_vector(NUM_WMASKS - 1 downto 0);

    signal sram_addr : std_logic_vector(ADDR_WIDTH - 3 downto 0);
    signal data_mask : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal dout_port0 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
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

    -- STEP 1: Latch all inputs on the rising edge
    -- This stops the FPU "flicker" from reaching the SRAM pins
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                addr_reg  <= (others => '0');
                din_reg   <= (others => '0');
                web_reg   <= '1'; -- Active low, so '1' is idle
                csb_reg   <= '1'; -- Active low, so '1' is idle
                wmask_reg <= (others => '0');
            else
                addr_reg  <= addr;
                din_reg   <= din;
                web_reg   <= web;
                csb_reg   <= csb;
                wmask_reg <= wmask;
            end if;
        end if;
    end process;

    -- STEP 2: Use the registered signals for the SRAM instance
    -- Note: We still perform the bit-stripping for the 32-bit word alignment
    sram_addr <= addr_reg(ADDR_WIDTH - 1 downto 2);
    
    gen_byte_mask : for i in 0 to 3 generate
        data_mask(8 * (i + 1) - 1 downto 8 * i) <= (others => wmask_reg(i));
    end generate;

    -- Output remains combinatorial as the SRAM has its own internal output regs
    dout <= dout_port0 when csb_reg = '0' else (others => '0');

    memory_inst : sky130_sram_2kbyte_1rw1r_32x512_8
    generic map (
        ADDR_WIDTH => ADDR_WIDTH - 2
    )
    port map(
        clk0   => clk,
        csb0   => csb_reg,  -- Latch ensures this is stable at posedge
        web0   => web_reg,  -- Latch ensures this is stable at posedge
        wmask0 => wmask_reg,
        addr0  => sram_addr,
        din0   => din_reg,  -- The Float 5 (40a00000) is now static here
        dout0  => dout_port0,
        -- Port 1 unused
        clk1   => '0',
        csb1   => '1',
        addr1  => (others => '0'),
        dout1  => open
    );
    
end architecture rtl;