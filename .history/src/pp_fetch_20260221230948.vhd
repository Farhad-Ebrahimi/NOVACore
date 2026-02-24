-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_constants.all;

--! @brief Instruction fetch unit.
entity pp_fetch is
	generic (
		RESET_ADDRESS : STD_LOGIC_VECTOR(31 downto 0)
	);
	port (
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;

		-- Instruction memory connections:
		imem_address : out STD_LOGIC_VECTOR(31 downto 0);
		imem_data_in : in STD_LOGIC_VECTOR(31 downto 0);
		imem_req : out STD_LOGIC;
		imem_ack : in STD_LOGIC;

		-- Control inputs:
		stall : in STD_LOGIC;
		-----stall_fpu : in STD_LOGIC;   -----internals stall or div stall for fpus 
		internal_stall : in STD_LOGIC;   -----internals stall or div stall for fpus 
		div_stall : in STD_LOGIC;   -----internals stall or div stall for fpus 
		flush : in STD_LOGIC;
		branch : in STD_LOGIC;
		jump_inst_id : in STD_LOGIC;
		jump_inst_ie : in STD_LOGIC;
		exception : in STD_LOGIC;

		branch_target : in STD_LOGIC_VECTOR(31 downto 0);
		pcid_bpu : in STD_LOGIC_VECTOR(31 downto 0);
		pcie_bpu : in STD_LOGIC_VECTOR(31 downto 0);
		evec : in STD_LOGIC_VECTOR(31 downto 0);

		-- Outputs to the instruction decode unit:
		do_flush : out STD_LOGIC;
		instruction_data : out STD_LOGIC_VECTOR(31 downto 0);
		instruction_address : out STD_LOGIC_VECTOR(31 downto 0);
		instruction_ready : out STD_LOGIC
	);
end entity pp_fetch;

architecture behaviour of pp_fetch is
	signal pc : STD_LOGIC_VECTOR(31 downto 0);
	signal pc_next : STD_LOGIC_VECTOR(31 downto 0);
	signal cancel_fetch : STD_LOGIC;
	signal wrong_prediction : STD_LOGIC;
	signal predicted_target : STD_LOGIC_VECTOR(31 downto 0);
	signal imem_data : STD_LOGIC_VECTOR(31 downto 0);
	signal pipeline_stall : std_logic;


begin

	imem_address <= pc_next when cancel_fetch = '0' else pc;

	pipeline_stall <= stall or internal_stall or div_stall;

	----stall_fpu <= internal_stall or div_stall;  -- for if stage and decode stage

	do_flush <= wrong_prediction;
	
	--instruction_data <= imem_data_in;    ----stalls for fpus are properly Ored, no dependencies
	instruction_data <= imem_data_in when (pipeline_stall = '0') and imem_ack='1'  else imem_data;
	----instruction_ready <= imem_ack and ((not stall) or ((not internal_stall) and (not div_stall))) and (not cancel_fetch) ;
	instruction_ready <= imem_ack
                     and (not stall)
					 or (not(stall_fpu))
                     and (not cancel_fetch);
	instruction_address <= pc;

	imem_req <= not reset;

	set_pc : process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				pc <= RESET_ADDRESS;
				cancel_fetch <= '0';
				imem_data <= (others=>'0');

			else
				if (exception = '1' or wrong_prediction = '1') and imem_ack = '0' then
					cancel_fetch <= '1';
					pc <= pc_next;
				elsif cancel_fetch = '1' and imem_ack = '1' then
					cancel_fetch <= '0';
				else
					pc <= pc_next;
				end if;
				if ( pipeline_stall = '0') and imem_ack = '1' then  ----or stall_fpu ='0'
				    imem_data <= imem_data_in;
				end if;

			end if;
		end if;
	end process set_pc;

	calc_next_pc : process (reset, stall,internal_stall, div_stall, exception, imem_ack, evec, pc, cancel_fetch, wrong_prediction, predicted_target)
	begin
		if exception = '1' then
			pc_next <= evec;
		elsif wrong_prediction = '1' then
			pc_next <= predicted_target;
		elsif imem_ack = '1' and (pipeline_stall = '0') and cancel_fetch = '0' then
			pc_next <= predicted_target;
		else
			pc_next <= pc;
		end if;
	end process calc_next_pc;

	Branch_prediction_unit : entity work.bpu
		generic map
		(
			INDEX_WIDTH => 9,
			RESET_ADDRESS => RESET_ADDRESS
		)
		port map
		(
			clk => clk,
			reset => reset,
			stall => stall,
			jump_inst_id => jump_inst_id,
			jump_inst_ie => jump_inst_ie,
			actual_taken => branch,
			actual_target => branch_target,
			pc_if => pc,
			pc_id => pcid_bpu,
			pc_ie => pcie_bpu,
			do_flush => wrong_prediction,
			trg_addr_o => predicted_target
		);

end architecture behaviour;