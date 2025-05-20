-- The Potato Processor - SoC design for the Arty FPGA board
-- (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all;

entity fsbl_rom_wrapper is
    generic (
        MEMORY_SIZE : natural := 1024 --! Memory size in bytes.
    );
    port (
        clk : in std_logic;
        reset : in std_logic;

        fsbl_adr_in : in std_logic_vector(9 downto 0);
        fsbl_dat_out : out std_logic_vector(31 downto 0);
        fsbl_cyc_in : in std_logic;
        fsbl_req : in std_logic;
        fsbl_sel_in : in std_logic_vector(3 downto 0)
    );
end entity fsbl_rom_wrapper;

architecture behaviour of fsbl_rom_wrapper is

    signal read_data : std_logic_vector(31 downto 0);
    signal data_mask : std_logic_vector(31 downto 0);

begin

    rom : entity work.fsbl_rom
        port map(
            clka => clk,
            addra => fsbl_adr_in(9 downto 2),
            douta => read_data
        );

    gen_byte_mask : for i in 0 to 3 generate
        data_mask(8 * (i + 1) - 1 downto 8 * i) <= (others => fsbl_sel_in(i));
    end generate;

    fsbl_dat_out <= read_data and data_mask ;
    
end architecture behaviour;