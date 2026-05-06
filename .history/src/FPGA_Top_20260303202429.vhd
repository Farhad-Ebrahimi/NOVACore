library ieee;
use ieee.std_logic_1164.all;

entity fpga_top is
    port(
        clk100mhz : in  std_logic;
        reset_n   : in  std_logic;

        uart0_txd : out std_logic;
        uart0_rxd : in  std_logic;

        uart1_txd : out std_logic;
        uart1_rxd : in  std_logic
    );
end entity;

architecture rtl of fpga_top is

    signal cpu_clk    : std_logic;
    signal clk_locked : std_logic;

begin

    -- Clock Wizard
    clkgen : entity work.clk_wiz_0
        port map(
            clk_in1  => clk100mhz,
            clk_out1 => cpu_clk,
            locked   => clk_locked
        );

    -- NOVACore SoC
    soc : entity work.toplevel
        port map(
            system_clk        => cpu_clk,
            system_clk_locked => clk_locked,
            reset_n           => reset_n,
            uart0_txd         => uart0_txd,
            uart0_rxd         => uart0_rxd,
            uart1_txd         => uart1_txd,
            uart1_rxd         => uart1_rxd
        );

end architecture;