library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity pp_soc_reset is
    generic (
        RESET_CYCLE_COUNT : natural := 1
    );
    port (
        reset_n : in std_logic;
        reset_out : out std_logic;
        system_clk : in std_logic;
        system_clk_locked : in std_logic
    );
end entity pp_soc_reset;

architecture Behavioral of pp_soc_reset is

    signal reset_sync : std_logic := '1';
    signal reset_count : natural range 0 to RESET_CYCLE_COUNT := 0;

    signal internal_reset : std_logic := '1';

begin

    process (system_clk)
        variable sync_1 : std_logic := '1';
        variable sync_2 : std_logic := '1';
    begin
        if rising_edge(system_clk) then
            reset_sync <= sync_1;
            sync_1 := not reset_n;
            
        end if;
    end process;

    process (system_clk)
    begin
        if rising_edge(system_clk) then
            if reset_sync = '1' or system_clk_locked = '0' then
                internal_reset <= '1';
                reset_count <= 0;
            elsif reset_count < RESET_CYCLE_COUNT then
                reset_count <= reset_count + 1;
                internal_reset <= '1';
            else
                internal_reset <= '0';
            end if;
        end if;
    end process;

    reset_out <= internal_reset;

end architecture Behavioral;