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
		imem_address : out STD_LOGIC_VECTOR(31 downto 0);   -----where to read from i.e pc
		imem_data_in : in STD_LOGIC_VECTOR(31 downto 0);    ----- the value to read
		imem_req : out STD_LOGIC;
		imem_ack : in STD_LOGIC;

		-- Control inputs:
		stall : in STD_LOGIC;
		stall_fpu : in STD_LOGIC;   -----internals stall or div stall for fpus 
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
		instruction_address : out STD_LOGIC_VECTOR(31 downto 0);  -----if_pc
		instruction_ready : out STD_LOGIC
	);
end entity pp_fetch;

architecture behaviour of pp_fetch is
	signal pc : STD_LOGIC_VECTOR(31 downto 0);
	signal pc_next : STD_LOGIC_VECTOR(31 downto 0);
	signal imem_data :  STD_LOGIC_VECTOR(31 downto 0);
	signal cancel_fetch : STD_LOGIC;
	signal wrong_prediction : STD_LOGIC;
	signal predicted_target : STD_LOGIC_VECTOR(31 downto 0);
	signal stall_fetch : STD_LOGIC;    -----2026-01-21

begin

	imem_address <= pc_next when cancel_fetch = '0' else pc;

	do_flush <= branch;

	-------------!internal_stall && !div_stall && !terminated_next in fetch 
	stall_fetch <= stall_fpu and cancel_fetch;   -----2026-01-21
	
	------stall_fpu condition added
	instruction_data <= imem_data_in ; ---- when  ---( stall = '0' and imem_ack='1' and stall_fetch = '0') else imem_data;
	instruction_ready <= imem_ack and (not stall) and (not cancel_fetch) and (not stall_fpu);
	instruction_address <= pc;

	imem_req <= not reset;

	set_pc: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				pc <= RESET_ADDRESS;
				cancel_fetch <= '0';
			else
				if (exception = '1' or branch = '1') and imem_ack = '0' then
					cancel_fetch <= '1';
					pc <= pc_next;
				elsif cancel_fetch = '1' and imem_ack = '1' then
					cancel_fetch <= '0';
				else
					pc <= pc_next;
				end if;
			end if;
		end if;
	end process set_pc;

	calc_next_pc: process(reset, stall, branch, exception, imem_ack, branch_target, evec, pc, cancel_fetch, stall_fpu)
	begin
		if exception = '1' then
			pc_next <= evec;
		elsif branch = '1' then
			pc_next <= branch_target;
		elsif imem_ack = '1' and (stall = '0' or stall_fpu = '0') and cancel_fetch = '0'  then
			pc_next <= std_logic_vector(unsigned(pc) + 4);
		else
			pc_next <= pc;
		end if;
	end process calc_next_pc;


	----from here we get the program counter and instruction will now pass into decode stage----
	
end architecture behaviour;