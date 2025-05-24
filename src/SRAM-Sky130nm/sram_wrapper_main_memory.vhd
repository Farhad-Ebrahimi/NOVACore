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
        addr : in std_logic_vector(12 downto 0);
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity main_memory_wrapper;

architecture rtl of main_memory_wrapper is

    signal sram_select : std_logic_vector(1 downto 0);

    signal web_intermediate : std_logic;
    signal csb0_intermediate : std_logic;
    signal csb1_intermediate : std_logic;
    signal csb2_intermediate : std_logic;
    signal csb3_intermediate : std_logic;

    signal sram_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal dout_reg : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram0 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram2 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram3 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    signal dout_sram_bank0 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram_bank1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram_bank2 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dout_sram_bank3 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    
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

begin

    sram_select <= addr(12 downto 11);
    sram_addr <= addr(10 downto 2);

    web_intermediate <= not web;

    csb0_intermediate <= '0' when (csb = '1' and (sram_select = "00")) else '1';
    csb1_intermediate <= '0' when (csb = '1' and (sram_select = "01")) else '1';
    csb2_intermediate <= '0' when (csb = '1' and (sram_select = "10")) else '1';
    csb3_intermediate <= '0' when (csb = '1' and (sram_select = "11")) else '1';

    process (dout_sram_bank0, dout_sram_bank1, dout_sram_bank2, dout_sram_bank3, web, sram_select, rst)
        variable temp : std_logic;
    begin
        if rst = '1' then
            dout_reg <= (others => '0');
        elsif web = '0' then
            temp := '1';
            case sram_select is
                when "00" =>
                    for i in dout_sram_bank0'range loop
                        if dout_sram_bank0(i) /= '0' and dout_sram_bank0(i) /= '1' then
                            temp := '0';
                        end if;
                    end loop;
                    if temp = '1' then
                        dout_reg <= dout_sram_bank0;
                    end if;

                when "01" =>
                    for i in dout_sram_bank1'range loop
                        if dout_sram_bank1(i) /= '0' and dout_sram_bank1(i) /= '1' then
                            temp := '0';
                        end if;
                    end loop;
                    if temp = '1' then
                        dout_reg <= dout_sram_bank1;
                    end if;

                when "10" =>
                    for i in dout_sram_bank2'range loop
                        if dout_sram_bank2(i) /= '0' and dout_sram_bank2(i) /= '1' then
                            temp := '0';
                        end if;
                    end loop;
                    if temp = '1' then
                        dout_reg <= dout_sram_bank2;
                    end if;

                when "11" =>
                    for i in dout_sram_bank3'range loop
                        if dout_sram_bank3(i) /= '0' and dout_sram_bank3(i) /= '1' then
                            temp := '0';
                        end if;
                    end loop;
                    if temp = '1' then
                        dout_reg <= dout_sram_bank3;
                    end if;

                when others =>
                    dout_reg <= (others => '0');
            end case;
        end if;
    end process;

    dout <= dout_reg;

    Bank_0 : sky130_sram_2kbyte_1rw1r_32x512_8
    port map(
        clk0 => clk,
        csb0 => csb0_intermediate,
        web0 => web_intermediate,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_sram_bank0,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_sram0
    );

    Bank_1 : sky130_sram_2kbyte_1rw1r_32x512_8
    port map(
        clk0 => clk,
        csb0 => csb1_intermediate,
        web0 => web_intermediate,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_sram_bank1,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_sram1
    );

    Bank_2 : sky130_sram_2kbyte_1rw1r_32x512_8
    port map(
        clk0 => clk,
        csb0 => csb2_intermediate,
        web0 => web_intermediate,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_sram_bank2,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_sram2
    );

    Bank_3 : sky130_sram_2kbyte_1rw1r_32x512_8
    port map(
        clk0 => clk,
        csb0 => csb3_intermediate,
        web0 => web_intermediate,
        wmask0 => wmask,
        addr0 => sram_addr,
        din0 => din,
        dout0 => dout_sram_bank3,
        clk1 => '1',
        csb1 => '1',
        addr1 => (others => '0'),
        dout1 => dout_sram3
    );

end architecture rtl;