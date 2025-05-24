-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

-- Based on:
-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

use work.pp_types.all;
use work.pp_utilities.all;

--! @brief The Potato Processor.
--! This file provides a Wishbone-compatible interface to the Potato processor.
entity pp_novacore is
	generic (
		PROCESSOR_ID : std_logic_vector(31 downto 0) := x"00000000"; --! Processor ID.
		RESET_ADDRESS : std_logic_vector(31 downto 0) := x"00000000"; --! Address of the first instruction to execute.
		MTIME_DIVIDER : positive := 5 --! Divider for the clock driving the MTIME counter.
	);
	port (
		clk : in std_logic;
		reset : in std_logic;

		-- Interrupts:
		irq : in std_logic_vector(7 downto 0);

		-- Test interface:
		test_context_out : out test_context;

		-- Wishbone interface:
		wb_adr_out : out std_logic_vector(31 downto 0);
		wb_sel_out : out std_logic_vector(3 downto 0);
		wb_cyc_out : out std_logic;
		wb_stb_out : out std_logic;
		wb_we_out : out std_logic;
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_dat_in : in std_logic_vector(31 downto 0);
		wb_ack_in : in std_logic
	);
end entity pp_novacore;

architecture behaviour of pp_novacore is

	-- Instruction memory signals:
	signal imem_address : std_logic_vector(31 downto 0);
	signal imem_data : std_logic_vector(31 downto 0);
	signal imem_req, imem_ack, imem_ack_control : std_logic;

	-- Data memory signals:
	signal dmem_address : std_logic_vector(31 downto 0);
	signal dmem_data_in : std_logic_vector(31 downto 0);
	signal dmem_data_out : std_logic_vector(31 downto 0);
	signal dmem_data_size : std_logic_vector(1 downto 0);
	signal dmem_read_req : std_logic;
	signal dmem_read_ack : std_logic;
	signal dmem_write_req : std_logic;
	signal dmem_write_ack : std_logic;

	-- Instruction memory signals (nv_memsys)
	signal imem_data_memsys : std_logic_vector(31 downto 0);
	signal imem_ack_memsys : std_logic;

	-- Data memory signals (nv_memsys)
	signal dmem_data_in_memsys : std_logic_vector(31 downto 0);
	signal dmem_read_ack_memsys : std_logic;
	signal dmem_write_ack_memsys : std_logic;

	-- keep ack in nv_memsys high until stall gets 0 
	signal processor_stalled : std_logic;
	
	-- Instruction memory signals (Wishbone adapter)
	signal imem_data_wb : std_logic_vector(31 downto 0);
	signal imem_ack_wb : std_logic;

	-- Data memory signals (Wishbone adapter)
	signal dmem_data_in_wb : std_logic_vector(31 downto 0);
	signal dmem_read_ack_wb : std_logic;
	signal dmem_write_ack_wb : std_logic;

	-- Wishbone signals:
	signal imem_inputs, dmem_if_inputs : wishbone_master_inputs;
	signal imem_outputs, dmem_if_outputs : wishbone_master_outputs;

	-- Arbiter signals:
	signal m1_inputs, m2_inputs : wishbone_master_inputs;
	signal m1_outputs, m2_outputs : wishbone_master_outputs;

begin

	processor : entity work.pp_core
		generic map(
			PROCESSOR_ID => PROCESSOR_ID,
			RESET_ADDRESS => RESET_ADDRESS
			) port map(
			clk => clk,
			reset => reset,
			imem_address => imem_address,
			imem_data_in => imem_data,
			imem_req => imem_req,
			imem_ack => imem_ack_control,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_in,     -- core input
			dmem_data_out => dmem_data_out,	  -- core output
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_read_ack => dmem_read_ack,
			dmem_write_req => dmem_write_req,
			dmem_write_ack => dmem_write_ack,
			test_context_out => test_context_out,
			irq => irq
		);

	-- nv_memsys: instruction & data memory
	instance_memsys : entity work.nv_memsys
		generic map(
			RESET_ADDRESS => RESET_ADDRESS
		)
		port map(
			clk => clk,
			reset => reset,
			imem_address => imem_address,
			imem_data => imem_data_memsys,
			imem_req => imem_req,
			imem_ack => imem_ack_memsys,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_out, -- mem input
			dmem_data_out => dmem_data_in_memsys, -- mem output
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_read_ack => dmem_read_ack_memsys,
			dmem_write_req => dmem_write_req,
			dmem_write_ack => dmem_write_ack_memsys
		);

	-- IMEM Wb adapter
	imem_if : entity work.pp_wb_adapter
		port map(
			clk => clk,
			reset => reset,
			mem_address => imem_address,
			mem_data_in => (others => '0'),
			mem_data_out => imem_data_wb,
			mem_data_size => (others => '0'),
			mem_read_req => imem_req,
			mem_read_ack => imem_ack_wb,
			mem_write_req => '0',
			mem_write_ack => open,
			wb_inputs => imem_inputs,
			wb_outputs => imem_outputs
		);

	dmem_if_inputs <= m1_inputs;
	m1_outputs <= dmem_if_outputs;

	imem_inputs <= m2_inputs;
	m2_outputs <= imem_outputs;

	-- DMEM Wb adapter
	dmem_if : entity work.pp_wb_adapter
		port map(
			clk => clk,
			reset => reset,
			mem_address => dmem_address,
			mem_data_in => dmem_data_out,
			mem_data_out => dmem_data_in_wb,
			mem_data_size => dmem_data_size,
			mem_read_req => dmem_read_req,
			mem_read_ack => dmem_read_ack_wb,
			mem_write_req => dmem_write_req,
			mem_write_ack => dmem_write_ack_wb,
			wb_inputs => dmem_if_inputs,
			wb_outputs => dmem_if_outputs
		);

	arbiter : entity work.pp_wb_arbiter
		port map(
			clk => clk,
			reset => reset,
			m1_inputs => m1_inputs,
			m1_outputs => m1_outputs,
			m2_inputs => m2_inputs,
			m2_outputs => m2_outputs,
			wb_adr_out => wb_adr_out,
			wb_sel_out => wb_sel_out,
			wb_cyc_out => wb_cyc_out,
			wb_stb_out => wb_stb_out,
			wb_we_out => wb_we_out,
			wb_dat_out => wb_dat_out,
			wb_dat_in => wb_dat_in,
			wb_ack_in => wb_ack_in
		);

	process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				imem_data <= (others => '0');
				imem_ack <= '0';
				dmem_data_in <= (others => '0');
				dmem_read_ack <= '0';
				dmem_write_ack <= '0';
			else
				-- Instruction memory mux
				if is_mem_addr(imem_address) then
					imem_data <= imem_data_memsys;
					imem_ack <= imem_ack_memsys;
				else
					imem_data <= imem_data_wb;
					imem_ack <= imem_ack_wb;
				end if;

				-- Data memory mux
				if is_mem_addr(dmem_address) then
					dmem_data_in <= dmem_data_in_memsys;
					dmem_read_ack <= dmem_read_ack_memsys;
					dmem_write_ack <= dmem_write_ack_memsys;
				else
					dmem_data_in <= dmem_data_in_wb;
					dmem_read_ack <= dmem_read_ack_wb;
					dmem_write_ack <= dmem_write_ack_wb;
				end if;
			end if;
		end if;
	end process;
	
	imem_ack_control <= imem_ack when (dmem_read_req = '0' and dmem_write_req = '0') else '0';

end architecture behaviour;

