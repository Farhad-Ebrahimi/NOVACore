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
	signal imem_req, imem_ack : std_logic;

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

	-- Internal registers to hold previous cycle inputs
	signal dmem_read_req_r : std_logic := '0';
	signal dmem_write_req_r : std_logic := '0';
	signal dmem_address_r : std_logic_vector(dmem_address'range);
	signal imem_address_r : std_logic_vector(imem_address'range);
	signal imem_req_r : std_logic := '0';

	type state_type is (IDLE, ST_NVDMEM, ST_NVIMEM, ST_WBDMEM);
	signal state : state_type := IDLE;

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
			imem_ack => imem_ack,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_in,
			dmem_data_out => dmem_data_out,
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
			dmem_data_in => dmem_data_out,
			dmem_data_out => dmem_data_in_memsys,
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_read_ack => dmem_read_ack_memsys,
			dmem_write_req => dmem_write_req,
			dmem_write_ack => dmem_write_ack_memsys
		);

	--------------------------------------------------------
	-- Wishbone Interface: Prepherial --> UART, TIMER, GPIO
	--------------------------------------------------------

	--	There will be no imem_requests to peripherials via wb;
	m2_outputs.adr <= (others => '0');
	m2_outputs.sel <= (others => '0');
	m2_outputs.cyc <= '0';
	m2_outputs.stb <= '0';
	m2_outputs.we <= '0';

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

	dmem_if_inputs <= m1_inputs;
	m1_outputs <= dmem_if_outputs;

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
	address_decoder_mux : process (
		state,
		dmem_read_ack_memsys, dmem_read_ack_wb,
		dmem_write_ack_memsys, dmem_write_ack_wb,
		dmem_data_in_memsys, dmem_data_in_wb,
		imem_ack_memsys, imem_data_memsys)
	begin

		dmem_read_ack <= '0';
		dmem_write_ack <= '0';
		-- dmem_data_in <= (others => '0');
		imem_ack <= '0';
		--imem_data <= (others => '0');

		case state is
			when ST_NVDMEM | ST_NVIMEM =>
				dmem_read_ack <= dmem_read_ack_memsys;
				dmem_write_ack <= dmem_write_ack_memsys;
				dmem_data_in <= dmem_data_in_memsys;
				imem_ack <= imem_ack_memsys;
				imem_data <= imem_data_memsys;

			when ST_WBDMEM =>
				dmem_read_ack <= dmem_read_ack_wb;
				dmem_write_ack <= dmem_write_ack_wb;
				dmem_data_in <= dmem_data_in_wb;

			when others =>
				null;
		end case;
	end process;

	address_decoder : process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= IDLE;
			else
				case state is
					when IDLE =>
						if dmem_read_req = '1' or dmem_write_req = '1' then
							if is_mem_addr(dmem_address) then
								-- Handle DMEM fetch (FSBL_ROM, SSBL_RAM, AEE_RAM, Main_Memory)
								state <= ST_NVDMEM;
							else
								-- Peripheral DMEM access (UART/TIMER via Wishbone)
								state <= ST_WBDMEM;
							end if;

						elsif imem_req = '1' and is_mem_addr(imem_address) then
							-- Handle IMEM fetch (FSBL_ROM, SSBL_RAM, AEE_RAM, Main_Memory)
							state <= ST_NVIMEM;
						end if;

					when ST_NVDMEM =>
						if dmem_read_ack_memsys = '1' or dmem_write_ack_memsys = '1' then
							state <= ST_NVIMEM;
						end if;

					when ST_WBDMEM =>
						if dmem_read_ack_wb = '1' or dmem_write_ack_wb = '1' then
							state <= ST_NVIMEM;
						end if;

					when ST_NVIMEM =>
						if dmem_read_req = '1' or dmem_write_req = '1' then
							-- IMEM fetch is interrupted by DMEM access
							if is_mem_addr(dmem_address) then
								state <= ST_NVDMEM;
							else
								state <= ST_WBDMEM;
							end if;
						end if;

					when others =>
						state <= IDLE;

				end case;
			end if;
		end if;
	end process address_decoder;
	
end architecture behaviour;