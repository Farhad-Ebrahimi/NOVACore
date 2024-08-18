-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2018 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>
--
--
-- 16.06.2023 Farhad
-- - Replace with XPM reset bridge to resolve timing issues.

library ieee, xpm;
use ieee.std_logic_1164.all;
use work.pp_utilities.all;
use xpm.vcomponents.all;

--! @brief System reset unit.
--! Because most resets in the processor core are synchronous, at least one
--! clock pulse has to be given to the processor while the reset signal is
--! asserted. However, if the clock generator is being reset at the same time,
--! the system clock might not run during reset, preventing the processor from
--! properly resetting.
entity pp_soc_reset is
	generic(
		RESET_CYCLE_COUNT : natural := 1
	);
	port(
		clk : in std_logic; --ignored

		reset_n   : in  std_logic;
		reset_out : out std_logic;

		system_clk        : in std_logic;
		system_clk_locked : in std_logic
	);
end entity pp_soc_reset;

architecture behaviour of pp_soc_reset is

	signal reset_int : std_logic := '0';
begin

   reset_int <= not (system_clk_locked and reset_n);

   reset_bridge : xpm_cdc_async_rst
   generic map (
      DEST_SYNC_FF => 2,
      INIT_SYNC_FF => 0,
      RST_ACTIVE_HIGH => 1
   )
   port map (
      dest_arst => reset_out,
      dest_clk => system_clk,
      src_arst => reset_int
   );

end architecture behaviour;
