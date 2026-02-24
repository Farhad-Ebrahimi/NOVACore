-- The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
-- (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
-- Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
-- Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

-- Based on:
-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_constants.all;
use work.pp_utilities.all;
use work.pp_csr.all;

--! @brief The Potato Processor is a simple processor core for use in FPGAs.
entity pp_core is
	generic (
		PROCESSOR_ID : STD_LOGIC_VECTOR(31 downto 0) := x"00000000"; --! Processor ID.
		RESET_ADDRESS : STD_LOGIC_VECTOR(31 downto 0) := x"00000000"; --! Address of the first instruction to execute.
		MTIME_DIVIDER : POSITIVE := 5; --! Divider for the clock driving the MTIME counter
		TIME_DIVIDER : POSITIVE := 5 --! Divider for the clock dirivng the TIME counter
	);
	port (
		-- Control inputs:
		clk : in STD_LOGIC;     --! Processor clock
		reset : in STD_LOGIC;    --! Reset signal

		-- Instruction memory interface:    -----equivalent to imem.mem maybe 
		imem_address : out STD_LOGIC_VECTOR(31 downto 0); --! Address of the next instruction   imem.mem data 
		imem_data_in : in STD_LOGIC_VECTOR(31 downto 0); --! Instruction input
		imem_req : out STD_LOGIC;
		imem_ack : in STD_LOGIC;

		-- Data memory interface:  ------still have doubts what this does
		dmem_address : out STD_LOGIC_VECTOR(31 downto 0); --! Data address
		dmem_data_in : in STD_LOGIC_VECTOR(31 downto 0); --! Input from the data memory   comes from upper modules
		dmem_data_out : out STD_LOGIC_VECTOR(31 downto 0); --! Ouptut to the data memory
		dmem_data_size : out STD_LOGIC_VECTOR(1 downto 0); --! Size of the data, 1 = 8 bits, 2 = 16 bits, 0 = 32 bits. 
		dmem_read_req : out STD_LOGIC; --! Data memory read request
		dmem_read_ack : in STD_LOGIC; --! Data memory read acknowledge
		dmem_write_req : out STD_LOGIC; --! Data memory write request
		dmem_write_ack : in STD_LOGIC; --! Data memory write acknowledge

		-- Test interface:
		test_context_out : out test_context; --! Test context output.

		-- External interrupt input:
		irq : in STD_LOGIC_VECTOR(7 downto 0); --! IRQ inputs.

		----------------------------------------
		stall : in STD_LOGIC --from fpu.sv
		
	);
end entity pp_core;

architecture behaviour of pp_core is

	------- Flush signals -------
	signal flush_if, flush_id, flush_ex : STD_LOGIC;

	------- Stall signals -------
	signal stall_if, stall_id, stall_ex, stall_mem, stall_freg : STD_LOGIC;   ----normal stall for if,id,ex and mem
	signal stall_exe_stg1_combined, stall_exe_stg2_combined : STD_LOGIC;  -- Combined stall signals for Execute stages

	-----signal stall_exe_stg1, stall_exe_stg2: STD_LOGIC;  -- Combined stall signals for Execute stages
	
	-- delibrate stall    -----what is that?
	signal stall_counter : integer range 0 to 1 := 0;
	signal delibrate_stall, insert_nop_id : std_logic;

	-- Signals used to determine if an instruction should be counted
	-- by the instret counter:
	signal if_count_instruction, id_count_instruction : STD_LOGIC;
	signal ex_count_instruction, mem_count_instruction : STD_LOGIC;
	signal wb_count_instruction : STD_LOGIC;

	-- CSR read port signals:
	signal csr_read_data : STD_LOGIC_VECTOR(31 downto 0);
	signal csr_read_address, csr_read_address_p : csr_address;

	-- Status register outputs:
	signal mtvec : STD_LOGIC_VECTOR(31 downto 0);
	signal mie : STD_LOGIC_VECTOR(31 downto 0);
	signal ie, ie1 : STD_LOGIC;

	-- Internal interrupt signals:
	signal software_interrupt, timer_interrupt : STD_LOGIC;

	-- Hazard detected in the execute stage:
	signal hazard_detected : STD_LOGIC;

	-- Branch targets:
	signal exception_target, branch_target : STD_LOGIC_VECTOR(31 downto 0);
	signal branch_taken, exception_taken_if, exception_taken_mem : STD_LOGIC;
	signal pcid_bpu, pcie_bpu : STD_LOGIC_VECTOR(31 downto 0);
	signal jump_inst_ie,jump_inst_id : STD_LOGIC;
	signal bpu_wrong_prediction : STD_LOGIC;
	signal branch_result : std_logic;
	
	-- Register file read ports:
	signal rs1_address_p, rs2_address_p : register_address;
	signal rs1_address, rs2_address : register_address;
	signal rs1_data, rs2_data : STD_LOGIC_VECTOR(31 downto 0);

	-- FP register file read ports:
	signal frs1_data, frs2_data : STD_LOGIC_VECTOR(31 downto 0);
	signal frs1_address_p, frs2_address_p : register_address;
	signal frs1_address, frs2_address : register_address;
	
	-- Data memory signals:
	signal dmem_address_p : STD_LOGIC_VECTOR(31 downto 0);
	signal dmem_data_size_p : STD_LOGIC_VECTOR(1 downto 0);
	signal dmem_data_out_p : STD_LOGIC_VECTOR(31 downto 0);
	signal dmem_read_req_p : STD_LOGIC;
	signal dmem_write_req_p : STD_LOGIC;

	-- Fetch stage signals:
	signal if_instruction, if_pc : STD_LOGIC_VECTOR(31 downto 0);
	signal if_instruction_ready : STD_LOGIC;

	-- Decode stage signals:
	signal id_funct3 : STD_LOGIC_VECTOR(2 downto 0);
	signal id_rd_address : register_address;
	signal id_frd_address : register_address;   ---for fpu
	signal id_rd_write : STD_LOGIC;
	signal id_frd_write : STD_LOGIC;           ---for fpu
	signal id_rs1_address : register_address;
	signal id_rs2_address : register_address;
	signal id_frs1_address : register_address;  -- FP register read address 1
	signal id_frs2_address : register_address;  -- FP register read address 2
	signal id_csr_address : csr_address;
	signal id_csr_write : csr_write_mode;
	signal id_csr_use_immediate : STD_LOGIC;
	signal id_shamt : STD_LOGIC_VECTOR(4 downto 0);    ---only for integers
	signal id_immediate : STD_LOGIC_VECTOR(31 downto 0);    ----only for integers
	signal id_branch : branch_type;
	signal id_alu_x_src, id_alu_y_src : alu_operand_source;
	signal id_alu_op : alu_operation;
	signal id_mem_op : memory_operation_type;
	signal id_mem_size : memory_operation_size;
	signal id_pc : STD_LOGIC_VECTOR(31 downto 0);
	signal id_exception : STD_LOGIC;
	signal id_exception_cause : csr_exception_cause;
	signal id_funct7 : STD_LOGIC_VECTOR(6 downto 0);  ---added for 

	-- Execute stage signals:
	signal ex_dmem_address : STD_LOGIC_VECTOR(31 downto 0);
	signal ex_dmem_data_size : STD_LOGIC_VECTOR(1 downto 0);
	signal ex_dmem_data_out : STD_LOGIC_VECTOR(31 downto 0);
	signal ex_dmem_read_req : STD_LOGIC;
	signal ex_dmem_write_req : STD_LOGIC;
	signal ex_rd_address : register_address;
	signal ex_frd_address : register_address;                         ---- fpu 2026
	signal ex_rd_data : STD_LOGIC_VECTOR(31 downto 0);
	signal ex_frd_data : STD_LOGIC_VECTOR(31 downto 0);                ---- fpu 2026

	signal ex_rd_write : STD_LOGIC;
	signal ex_frd_write : STD_LOGIC;                                   ---- fpu 2026
	signal ex_pc : STD_LOGIC_VECTOR(31 downto 0);
	signal ex_csr_address : csr_address;
	signal ex_csr_write : csr_write_mode;
	signal ex_csr_data : STD_LOGIC_VECTOR(31 downto 0);
	signal ex_branch : branch_type;
	signal ex_mem_op : memory_operation_type;
	signal ex_mem_size : memory_operation_size;
	signal ex_exception_context_if  : csr_exception_context;
	signal ex_exception_context_mem : csr_exception_context;

	-- Memory stage signals:
	signal mem_rd_write : STD_LOGIC;
	signal mem_rd_address : register_address;
	signal mem_rd_data : STD_LOGIC_VECTOR(31 downto 0);

	signal mem_frd_write : STD_LOGIC;             ---- fpu 2026
	signal mem_frd_data : STD_LOGIC_VECTOR(31 downto 0);  ---- fpu 2026 
	signal mem_frd_address : register_address;    ---- fpu 2026

	signal mem_csr_address : csr_address;
	signal mem_csr_write : csr_write_mode;
	signal mem_csr_data : STD_LOGIC_VECTOR(31 downto 0);
	signal mem_mem_op : memory_operation_type;

	signal mem_exception : STD_LOGIC;
	signal mem_exception_context : csr_exception_context;

	-- Writeback signals:
	signal wb_rd_address : register_address;
	signal wb_rd_data : STD_LOGIC_VECTOR(31 downto 0);
	signal wb_rd_write : STD_LOGIC;
    
	signal wb_frd_address : register_address;   ---- fpu 2026
	signal wb_frd_data : STD_LOGIC_VECTOR(31 downto 0);  ---- fpu 2026
	signal wb_frd_write : STD_LOGIC;   ---- fpu 2026


	signal wb_csr_address : csr_address;
	signal wb_csr_write : csr_write_mode;
	signal wb_csr_data : STD_LOGIC_VECTOR(31 downto 0);

	signal wb_exception : STD_LOGIC;
	signal wb_exception_context : csr_exception_context;
	
	signal dmem_read_ack_r  : std_logic;
    signal dmem_write_ack_r : std_logic;
    signal dmem_data_in_r :std_logic_vector(31 downto 0);

	----------------------div stall signals 2026-------------------------

		-- Division stall control
	signal div_start          : std_logic;                          -- Start division computation
	signal div_done           : std_logic;                          -- Division complete flag
	signal div_busy           : std_logic;                          -- Division in progress
	signal div_stall          : std_logic;                          -- Stall IF + Decode during pre-wait (counters 0-3)
	signal div_exec_stall     : std_logic;                          -- Stall Execute when DIV in Execute (counter >= 4)
	signal div_counter        : integer range 0 to 63;              -- Counter: 0-33 (34 cycles total)
	signal div_detected       : std_logic;                          -- DIV opcode detected in Decode
	signal div_op1_latched    : std_logic_vector(31 downto 0);      -- Captured dividend
	signal div_op2_latched    : std_logic_vector(31 downto 0);      -- Captured divisor
	signal div_rm_latched     : std_logic_vector(2 downto 0);       -- Captured rounding mode
	signal div_rd_latched     : std_logic_vector(4 downto 0);       -- Captured destination register
	-------------------------------------coming from decode stage-------------------------------------------------------
	signal  decode_instruction_out : std_logic_vector(31 downto 0);  -- Current instruction in Decode
	--signal  op1_out : std_logic_vector(31 downto 0);	
	--signal  op2_out : std_logic_vector(31 downto 0);
	--signal 	frd_out : std_logic_vector(4 downto 0);
	signal  opcode : std_logic_vector(4 downto 0);	
	signal  internal_stall : STD_LOGIC;	
	signal  decode_valid_out : STD_LOGIC; 
	signal stall_fpu : STD_LOGIC;
	signal  ex_valid_out : STD_LOGIC;	
     ----------------------enabling signals to choose which operation to perform. need to check this
	signal en_fadd : std_logic;
  	signal en_fsub : std_logic;
  	signal en_fmul : std_logic;
  	signal en_fdiv : std_logic;

	signal immediate_fp : std_logic_vector(31 downto 0);  -- Immediate for floating-point instructions, coming from immediate decoder
	
	--------------------------------------------------------------------
    
begin

	stall_if <=  stall_id or delibrate_stall or insert_nop_id;
	stall_id <= stall_ex;   ---internal stall added. 
	stall_ex <= hazard_detected or stall_mem ;--or internal_stall; --or internal_stall; --- internal stall added.
	stall_mem <= to_std_logic(memop_is_load(mem_mem_op) and (dmem_read_ack_r = '0'))
		or to_std_logic(((mem_mem_op = MEMOP_TYPE_STORE)  and (dmem_write_ack_r = '0'));   ----or (mem_mem_op = MEMOP_TYPE_STORE_FP))
	
	-- Combined stall signals for Execute stages (must include internal_stall for DIV)
	stall_exe_stg1_combined <= stall_ex or internal_stall;---not used
	stall_exe_stg2_combined <= stall_mem or internal_stall;---not used
	stall_freg <= internal_stall or div_stall;
		
    jump_inst_id <= '1' when (id_branch/=BRANCH_NONE) else '0';

	flush_if <= (bpu_wrong_prediction or exception_taken_if) and not stall_if;
	flush_id <= (bpu_wrong_prediction or exception_taken_if) and not stall_id;
	flush_ex <= (bpu_wrong_prediction or exception_taken_if) and not stall_ex;


	--------------------fpu stall----------------------
	-- FPU.cpp:62:5  ----update_stall
	internal_stall <= stall or div_exec_stall;  -- Full pipeline stall when DIV in Execute,MEM and WB
	stall_fpu <= internal_stall or div_stall;   -- for if stage and decode stage	
	-------------------------------------------------------------------
   --------0x53 for fpus    ------rs1_data and rs2_data and  id_rd_address might not be needed 
	--op1_out <= frs1_data when (opcode = "10100") else (others => '0') ;  -- FP reads if FP opcode
	--op2_out <= frs2_data when (opcode = "10100") else (others => '0') ;  -- FP reads if FP opcode  
	--frd_out  <= id_frd_address when (opcode = "10100") else (others => '0');  -- FP rd if FP opcode
	
	------- Control and status module -------
	csr_unit : entity work.pp_csr_unit
		generic map(
			PROCESSOR_ID => PROCESSOR_ID,
			MTIME_DIVIDER => MTIME_DIVIDER,
			TIME_DIVIDER => TIME_DIVIDER
			) port map(
			clk => clk,
			reset => reset,
			irq => irq,
			count_instruction => wb_count_instruction,
			test_context_out => test_context_out,
			read_address => csr_read_address,
			read_data_out => csr_read_data,
			write_address => wb_csr_address,
			write_data_in => wb_csr_data,
			write_mode => wb_csr_write,
			exception_context => wb_exception_context,
			exception_context_write => wb_exception,
			mie_out => mie,
			mtvec_out => mtvec,
			ie_out => ie,
			ie1_out => ie1,
			software_interrupt_out => software_interrupt,
			timer_interrupt_out => timer_interrupt
		);
---------------------------------need to check the stall for csr read address------------------------
	csr_read_address <= id_csr_address when stall_ex = '0' else
		csr_read_address_p;
	store_previous_csr_addr : process (clk, stall_ex)
	begin
		if rising_edge(clk) and stall_ex = '0' then
			csr_read_address_p <= id_csr_address;
		end if;
	end process store_previous_csr_addr;

	------- Register file -------
	regfile : entity work.pp_register_file
		port map(
			clk => clk,
			rs1_addr => rs1_address,
			rs2_addr => rs2_address,
			rs1_data => rs1_data,
			rs2_data => rs2_data,
			rd_addr => wb_rd_address,
			rd_data => wb_rd_data,
			rd_write => wb_rd_write
		);

	rs1_address <= id_rs1_address when stall_ex = '0' else
		rs1_address_p;
	rs2_address <= id_rs2_address when stall_ex = '0' else
		rs2_address_p;

	store_previous_rsaddr : process (clk, stall_ex)
	begin
		if rising_edge(clk) and stall_ex = '0' then
			rs1_address_p <= id_rs1_address;
			rs2_address_p <= id_rs2_address;
		end if;
	end process store_previous_rsaddr;
	
	---------------------fpu register file instantiation 2026-------------------------
      fpu_regfile : entity work.pp_fpu_register_file
		port map(
			clk => clk,
			frs1_addr => frs1_address,
			frs1_data => frs1_data,
			frs2_addr => frs2_address,
			frs2_data => frs2_data,
			frd_addr => wb_frd_address,  ---- in signal 
			frd_data => wb_frd_data,
			frd_write => wb_frd_write
		);

	frs1_address <= id_frs1_address when stall_freg = '0' else
		frs1_address_p;
	frs2_address <= id_frs2_address when stall_freg = '0' else
		frs2_address_p;



	store_previous_frsaddr : process (clk, stall_freg)
		begin
		if rising_edge(clk) and stall_freg = '0' then
			frs1_address_p <= id_frs1_address;
			frs2_address_p <= id_frs2_address;
		end if;
	end process store_previous_frsaddr;

	------- Instruction Fetch (IF) Stage -------
	fetch : entity work.pp_fetch
		generic map(
			RESET_ADDRESS => RESET_ADDRESS
			) port map(
			clk => clk,
			reset => reset,
			imem_address => imem_address,
			imem_data_in => imem_data_in,
			imem_req => imem_req,
			imem_ack => imem_ack,
			stall => stall_if,    
			flush => flush_if,
			stall_fpu => stall_fpu, --added 2026
			branch => branch_taken,
			jump_inst_id => jump_inst_id,
			jump_inst_ie => jump_inst_ie,
			pcid_bpu => id_pc,
			pcie_bpu => pcie_bpu,
			do_flush => bpu_wrong_prediction,
			exception => exception_taken_if,
			branch_target => branch_target,
			evec => exception_target,
			instruction_data => if_instruction,
			instruction_address => if_pc,
			instruction_ready => if_instruction_ready
		);
	if_count_instruction <= if_instruction_ready;
	

	------- Instruction Decode (ID) Stage -------
	decode : entity work.pp_decode
		generic map(
			RESET_ADDRESS => RESET_ADDRESS,
			PROCESSOR_ID => PROCESSOR_ID
			) port map(
			clk => clk,
			reset => reset,
			flush => flush_id,
			stall => stall_id,
			stall_fpu => stall_fpu,  --added 2026
			instruction_data => if_instruction,
			instruction_address => if_pc,
			instruction_ready => if_instruction_ready,
			instruction_count => if_count_instruction,
			insert_nop_id => insert_nop_id,
			funct3 => id_funct3,
			rs1_addr => id_rs1_address,
			rs2_addr => id_rs2_address,
			rd_addr => id_rd_address,
			opcode_out => opcode,  ----added
			decode_valid_out => decode_valid_out, 
			-----------------------------------------------
			frs1_addr => id_frs1_address,  ----fpu
			frs2_addr => id_frs2_address,   ---- fpu
			frd_addr => id_frd_address,    -----fpu
			instruction_out => decode_instruction_out,  --fpuS
			div_detected_out => div_detected,   
			-----------------------------------------------
			csr_addr => id_csr_address,
			shamt => id_shamt,
			immediate => id_immediate,
			immediate_fp => immediate_fp,  -- Immediate for floating-point instructions
			rd_write => id_rd_write,
			frd_write => id_frd_write,
			branch => id_branch,
			alu_x_src => id_alu_x_src,
			alu_y_src => id_alu_y_src,
			alu_op => id_alu_op,
			mem_op => id_mem_op,
			mem_size => id_mem_size,
			count_instruction => id_count_instruction,
			pc => id_pc,
			csr_write => id_csr_write,
			csr_use_imm => id_csr_use_immediate,
			decode_exception => id_exception,
			decode_exception_cause => id_exception_cause
		);
---------------------------------------------------------------------


 --int2float_frs1 : entity work.pp_int_2_float is
  --  port(
  --      data_in => open,    -
  --      alu_op_in => id_alu_op,                   
  --      frd_data_out => frs1_data  
  --  );



   --int2float_frs2 : entity work.pp_int_2_float is
  --  port(
  --      data_in => open,    -
  --      alu_op_in => id_alu_op,                   
  --      frd_data_out => frs2_data  
  --  );

---------------------------------------------------------------------
	------- Execute (EX) Stage -------
	execute : entity work.pp_execute
		port map(
			clk => clk,
			reset => reset,
			en_fadd => en_fadd,
			en_fsub => en_fsub,
  			en_fmul => en_fmul,
  			en_fdiv => en_fdiv,

			internal_stall => internal_stall,
			stall_exe_stg1 => stall_ex,
			stall_exe_stg2 => stall_mem,
			flush => flush_ex,
			irq => irq,
			software_interrupt => software_interrupt,
			timer_interrupt => timer_interrupt,
			dmem_address => ex_dmem_address,
			dmem_data_size => ex_dmem_data_size,
			dmem_data_out => ex_dmem_data_out,
			dmem_read_req => ex_dmem_read_req,
			dmem_write_req => ex_dmem_write_req,
			rs1_addr_in => rs1_address,  
			rs2_addr_in => rs2_address,  
			rd_addr_in => id_rd_address,     ----- from decode 
			rd_addr_out => ex_rd_address,
			rs1_data_in => rs1_data,    ----need to make for fpu
			rs2_data_in => rs2_data,   ----need to make for fpu

			--------------------------------------------
            frs1_addr_in => frs1_address,   ----need to make for fpu
			frs2_addr_in => frs2_address,  ----need to make for fpu
			frd_addr_in => id_frd_address,  ----need to make for fpu
			frd_addr_out => ex_frd_address,
			frs1_data_in => frs1_data,    ----op1_out,    ----need to make for fpu     this is the value of div_operand1
			frs2_data_in => frs2_data,   ----need to make for fpu       this is the value of div_operand2
			div_start => div_start,
			div_done => div_done,
			div_busy_out => div_busy,
			div_op1 => div_op1_latched,
			div_op2 => div_op2_latched,
			div_rm => div_rm_latched,
			div_rd => div_rd_latched,
			instruction_in => decode_instruction_out,   -----coming from decode stage
			opcode_in => opcode,
			valid_in => decode_valid_out,
			immediate_fp_in => immediate_fp, ----added
			
	       ----------------------------------------------
			shamt_in => id_shamt,
			immediate_in => id_immediate,
			funct3_in => id_funct3,
			pc_in => id_pc,
			pc_out => ex_pc,
			csr_addr_in => csr_read_address,
			csr_addr_out => ex_csr_address,
			csr_write_in => id_csr_write,
			csr_write_out => ex_csr_write,
			csr_value_in => csr_read_data,
			csr_value_out => ex_csr_data,
			csr_use_immediate_in => id_csr_use_immediate,
			alu_op_in => id_alu_op,
			alu_x_src_in => id_alu_x_src,
			alu_y_src_in => id_alu_y_src,
			rd_write_in => id_rd_write,
			rd_write_out => ex_rd_write,
			rd_data_out => ex_rd_data,
			frd_write_in => id_frd_write,
			frd_write_out => ex_frd_write,
			frd_data_out => ex_frd_data,    ----- added for fpu
			branch_in => id_branch,
			branch_out => ex_branch,
			mem_op_in => id_mem_op,
			mem_op_out => ex_mem_op,
			mem_size_in => id_mem_size,
			mem_size_out => ex_mem_size,
			count_instruction_in => id_count_instruction,
			count_instruction_out => ex_count_instruction,
			ie_in => ie,
			ie1_in => ie1,
			mie_in => mie,
			mtvec_in => mtvec,
			mtvec_out => exception_target,
			decode_exception_in => id_exception,
			decode_exception_cause_in => id_exception_cause,
			exception_out_if => exception_taken_if,
			exception_context_out_if => ex_exception_context_if,
			exception_out_mem => exception_taken_mem,
			exception_context_out_mem => ex_exception_context_mem,
			jump_out => branch_taken,
			jump_inst => jump_inst_ie,
			pcie_bpu => pcie_bpu,
			jump_target_out => branch_target,
			mem_rd_write => mem_rd_write,
			mem_rd_addr => mem_rd_address,
			mem_rd_value => mem_rd_data,
			mem_frd_value => mem_frd_data,   ------2026
			mem_csr_addr => mem_csr_address,
			mem_csr_write => mem_csr_write,
			mem_exception => mem_exception,
			mem_frd_addr => mem_frd_address,
			wb_rd_write => wb_rd_write,
			wb_rd_addr => wb_rd_address,
			wb_rd_value => wb_rd_data,

			wb_frd_write => wb_frd_write,
			wb_frd_addr => wb_frd_address,
			wb_frd_value => wb_frd_data,
			mem_frd_write => mem_frd_write,
			


			wb_csr_addr => wb_csr_address,
			wb_csr_write => wb_csr_write,
			wb_exception => wb_exception,
			mem_mem_op => mem_mem_op,
			hazard_detected => hazard_detected
		);

------------------------need to check the stall condition ----------------
	dmem_address <= ex_dmem_address when stall_mem = '0' else
		dmem_address_p;
	dmem_data_size <= ex_dmem_data_size when stall_mem = '0' else
		dmem_data_size_p;
	dmem_data_out <= ex_dmem_data_out when stall_mem = '0' else
		dmem_data_out_p;
	dmem_read_req <= ex_dmem_read_req when stall_mem = '0' else
		dmem_read_req_p;
	dmem_write_req <= ex_dmem_write_req when stall_mem = '0' else
		dmem_write_req_p;

	store_previous_dmem_address : process (clk, stall_mem)
	begin
		if rising_edge(clk) and stall_mem = '0' then
			dmem_address_p <= ex_dmem_address;
			dmem_data_size_p <= ex_dmem_data_size;
			dmem_data_out_p <= ex_dmem_data_out;
			dmem_read_req_p <= ex_dmem_read_req;
			dmem_write_req_p <= ex_dmem_write_req;
		end if;
	end process store_previous_dmem_address;

	------- Memory (MEM) Stage -------
	memory : entity work.pp_memory
		port map(
			clk => clk,
			reset => reset,
			stall => stall_mem,
			dmem_data_in => dmem_data_in_r,
			dmem_read_ack => dmem_read_ack_r,
			dmem_write_ack => dmem_write_ack_r,
			pc => ex_pc,
			internal_stall => internal_stall,  ---added fpu 2026
			rd_write_in => ex_rd_write,
			rd_write_out => mem_rd_write,
			rd_data_in => ex_rd_data,
			rd_data_out => mem_rd_data,
			rd_addr_in => ex_rd_address,
			rd_addr_out => mem_rd_address,
			----------------------------------------
			frd_write_in => ex_frd_write,
			frd_data_in => ex_frd_data,
			frd_addr_in => ex_frd_address,
			frd_write_out => mem_frd_write,
			frd_data_out => mem_frd_data,
			frd_addr_out => mem_frd_address,
			---------------------------------------------
			branch => ex_branch,
			mem_op_in => ex_mem_op,
			mem_op_out => mem_mem_op,
			mem_size_in => ex_mem_size,
			count_instr_in => ex_count_instruction,
			count_instr_out => mem_count_instruction,
			exception_in => exception_taken_mem,
			exception_out => mem_exception,
			exception_context_in => ex_exception_context_mem,
			exception_context_out => mem_exception_context,
			csr_addr_in => ex_csr_address,
			csr_addr_out => mem_csr_address,
			csr_write_in => ex_csr_write,
			csr_write_out => mem_csr_write,
			csr_data_in => ex_csr_data,
			csr_data_out => mem_csr_data
		);

	------- Writeback (WB) Stage -------
	writeback : entity work.pp_writeback
		port map(
			clk => clk,
			reset => reset,
			stall => internal_stall,  ---added fpu 2026
			count_instr_in => mem_count_instruction,
			count_instr_out => wb_count_instruction,
			exception_ctx_in => mem_exception_context,
			exception_ctx_out => wb_exception_context,
			exception_in => mem_exception,
			exception_out => wb_exception,
			csr_write_in => mem_csr_write,
			csr_write_out => wb_csr_write,
			csr_data_in => mem_csr_data,
			csr_data_out => wb_csr_data,
			csr_addr_in => mem_csr_address,
			csr_addr_out => wb_csr_address,
			rd_addr_in => mem_rd_address,
			rd_addr_out => wb_rd_address,
			rd_write_in => mem_rd_write,
			rd_write_out => wb_rd_write,
			rd_data_in => mem_rd_data,
			rd_data_out => wb_rd_data,
			--------------------------------------------
			frd_addr_in => mem_frd_address,
			frd_addr_out => wb_frd_address,   -----from wb
			frd_write_in => mem_frd_write,
			frd_write_out => wb_frd_write,
			frd_data_in => mem_frd_data,
			frd_data_out => wb_frd_data
		);
		
		
   --  delibrate stall because of Stor instruction 
    stall_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                delibrate_stall <= '0';
                stall_counter <= 0;
                dmem_read_ack_r <= '0';
                dmem_write_ack_r  <= '0';
                dmem_data_in_r <= (others => '0');
            else
                
                dmem_read_ack_r <= dmem_read_ack;
                dmem_write_ack_r  <= dmem_write_ack;
                dmem_data_in_r <= dmem_data_in;   -----comes from upper module and stored here.
                if (id_mem_op = MEMOP_TYPE_STORE ) and stall_counter = 0 then
                    delibrate_stall <= '1';
                    stall_counter <= 1;
                elsif stall_counter = 1 then
                    delibrate_stall <= '0';
                    stall_counter <= 0;
                else
                    delibrate_stall <= '0';
                end if;
            end if;
        end if;
    end process;

-----if_instruction 
--		id_funct7 <= if_instruction(31 downto 25);  ----added for fpu to detect div instruction in decode stage. 
----------------------------added for fpu operations--------------------------------------
--	---- DIV Detection (combinational)  only for fpus
--	div_detected <= '1' when (id_funct7 = "0001100" and 
--	                    		 decode_valid_out = '1' and 
--	                           div_stall = '0' and 
--	                           div_exec_stall = '0') else '0';

-- Division Stall Control (sequential)
DivStall: process(clk)
begin
    if rising_edge(clk) then
        if (reset = '1') then
            div_counter <= 0;
            div_stall   <= '0';
            div_start   <= '0';
            div_exec_stall <= '0';
            div_op1_latched <= (others => '0');
            div_op2_latched <= (others => '0');
            div_rm_latched  <= (others => '0');
            div_rd_latched  <= (others => '0');
        
        elsif (div_counter = 0) then
            -- IDLE state - check for new DIV
            if (div_detected = '1') then
                div_op1_latched <= frs1_data; ---- op1_out;
                div_op2_latched <= frs2_data; ---op2_out;
                div_rm_latched  <= decode_instruction_out(14 downto 12);
                div_rd_latched  <= id_frd_address;   ---frd_out;
                div_counter <= 1;
                div_stall   <= '1';
                div_start   <= '0';
                div_exec_stall <= '0';
            else 
                div_stall <= '0';
                div_start <= '0';
                div_exec_stall <= '0';
            end if;
        
        elsif (div_counter = 1) then
            -- Pre-wait cycle 1: Freeze entire pipeline
            
            div_counter <= 2;
            div_stall   <= '1';         -- Freeze front-end (IF + Decode)
            div_start   <= '0';
            div_exec_stall <= '1';      -- Freeze Execute too
            
        elsif (div_counter = 2) then
            -- Pre-wait cycle 2: Keep entire pipeline frozen
            div_counter <= 3;
            div_stall   <= '1';
            div_start   <= '0';
            div_exec_stall <= '1';
            
        elsif (div_counter = 3) then
            -- Transfer: DIV moves from Decode to Execute
            
            div_counter <= 4;
            div_stall   <= '0';         -- Release front-end
            div_start   <= '1';         -- Start divider
            div_exec_stall <= '1';      -- Hold Execute for 30+ cycles
            
        elsif (div_counter >= 4) then
            -- counter >= 4: Waiting for division to complete
            if (div_done = '1') then
                -- CRITICAL: IMMEDIATELY release stall when done
                
                div_counter <= 0;
                div_stall   <= '0';
                div_start   <= '0';
                div_exec_stall <= '0';
            else 
                -- Still computing: maintain stall
               -- if (div_counter = 4) then
                    --report "[DIV_WAITING] div_counter=4 div_done=" & std_logic'image(div_done) & " at " & time'image(now);
               -- end if;
                div_counter <= div_counter + 1;
                div_stall   <= '0';
                div_start   <= '0';
                div_exec_stall <= '1';
            end if;
        end if;
    end if;
end process DivStall;

end architecture behaviour;