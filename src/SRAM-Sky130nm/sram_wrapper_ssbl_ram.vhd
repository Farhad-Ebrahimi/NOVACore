-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ssbl_ram_wrapper is
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
        stb : in std_logic;
        wmask : in std_logic_vector(NUM_WMASKS - 1 downto 0);
        addr : in std_logic_vector(ADDR_WIDTH + 1 downto 0);
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ack_out : out std_logic
    );
end entity ssbl_ram_wrapper;

architecture rtl of ssbl_ram_wrapper is
    
    signal web_intermediate : std_logic;
    signal csb_intermediate : std_logic;
    
    signal sram_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal dout_sram : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram_blocks : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    component sky130_sram_2kbyte_1rw1r_32x512_8 is
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

    type state_type is (IDLE, ACK);
	signal state : state_type;

	signal read_ack : std_logic;

begin

    sram_addr <= addr(10 downto 2);

    ack_out <= read_ack and stb;
    web_intermediate <= not web;

    csb_intermediate <= '0' when (csb = '1' and stb = '1') else '1';

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                read_ack <= '0';
                state <= IDLE;
            else
                if csb = '1' then
                    case state is
                        when IDLE =>
                            if stb = '1' and web = '1' then
                                read_ack <= '1';
                                state <= ACK;
                            elsif stb = '1' then
                                read_ack <= '1';
                                state <= ACK;
                            end if;
                        when ACK =>
                            if stb = '0' then
                                read_ack <= '0';
                                state <= IDLE;
                            end if;
                    end case;
                else
                    state <= IDLE;
                    read_ack <= '0';
                end if;
            end if;
        end if;
    end process;

    Bank_0 : sky130_sram_2kbyte_1rw1r_32x512_8
    port map(
        clk0 => clk,
        csb0 => csb_intermediate,
        web0 => web_intermediate,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_sram_blocks,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_sram
    );

    dout <= dout_sram_blocks when csb_intermediate='0' else (others=>'0');

end architecture rtl;