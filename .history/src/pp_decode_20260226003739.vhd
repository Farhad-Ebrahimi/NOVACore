-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_utilities.all;
use work.pp_constants.all;
use work.pp_csr.all;

--! @brief Instruction decode unit.
entity pp_decode is
	generic(
		RESET_ADDRESS : std_logic_vector(31 downto 0);
		PROCESSOR_ID  : std_logic_vector(31 downto 0)
	);
	port(
		clk    : in std_logic;
		reset  : in std_logic;

		flush : in std_logic;
		stall : in std_logic;
		stall_fpu : in std_logic;

		-- Instruction input:
		instruction_data    : in std_logic_vector(31 downto 0);
		instruction_address : in std_logic_vector(31 downto 0);
		instruction_ready   : in std_logic;
		instruction_count   : in std_logic;
		insert_nop_id       : out std_logic;
		div_detected_out : out std_logic;  --! Signal indicating that a DIV instruction has been detected and is not currently stalled.

		-- Register addresses:
		rs1_addr, rs2_addr, rd_addr : out register_address;
		csr_addr : out csr_address;

		frs1_addr,frs2_addr, frd_addr : out register_address;  --- for FPU

		-- Shamt value for shift operations: not for floats
		shamt  : out std_logic_vector(4 downto 0);
		funct3 : out std_logic_vector(2 downto 0);

		opcode_out : out std_logic_vector(4 downto 0);
		decode_valid_out : out std_logic;  
		instruction_out : out std_logic_vector(31 downto 0);  --added


		-- Immediate value for immediate instructions: not for floats
		immediate : out std_logic_vector(31 downto 0);
		immediate_fp : out std_logic_vector(31 downto 0) ; -- Immediate for floating-point instructions,

		-- Control signals:
		rd_write          : out std_logic;
		frd_write         : out std_logic;  --! FPU register write signal
		branch            : out branch_type;
		alu_x_src         : out alu_operand_source;   ----need to check if needed for floats
		alu_y_src         : out alu_operand_source;   ----need to check if needed for floats
		alu_op            : out alu_operation;
		mem_op            : out memory_operation_type;
		mem_size          : out memory_operation_size;
		count_instruction : out std_logic;

		-- Instruction address:
		pc : out std_logic_vector(31 downto 0);

		-- CSR control signals:
		csr_write   : out csr_write_mode;
		csr_use_imm : out std_logic;

		-- Exception output signals:
		decode_exception       : out std_logic;
		decode_exception_cause : out csr_exception_cause
	);

end entity pp_decode;

architecture behaviour of pp_decode is
	signal instruction     : std_logic_vector(31 downto 0);
	signal immediate_value : std_logic_vector(31 downto 0);
	signal rd_addr_reg : register_address;
	signal insert_nop, nop_trigger, rd_write_reg ,frd_write_reg : std_logic;
	signal alu_op_reg : alu_operation;
	signal frd_addr_reg : register_address;  ---for fpu
	signal decode_valid : std_logic;
	signal immediate_fp_out : std_logic_vector(31 downto 0);  -- Immediate for floating-point 
	
begin

	immediate <= immediate_value;
	immediate_fp <= immediate_fp_out;
	alu_op <= alu_op_reg;
	rd_write <= rd_write_reg;
	frd_write <= frd_write_reg;  --- for FPU
	decode_valid_out <= decode_valid;
	
	-- Instruction fetch and hold
	get_instruction: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				instruction <= RISCV_NOP;
				pc <= RESET_ADDRESS;
				count_instruction <= '0';
			elsif stall = '1' or stall_fpu = '1' then   -----or stall_fpu = '1'so when division is detected we hold the pc and stall deocde
				count_instruction <= '0'; -- hold PC and instruction
			elsif flush = '1' or instruction_ready = '0' or insert_nop = '1' then -----or insert_nop = '1'  then ----or insert_nop = '1'  then    ---- or insert_nop = '1'
				instruction <= RISCV_NOP;
				count_instruction <= '0';
			else
				instruction <= instruction_data;
				count_instruction <= instruction_count;
				pc <= instruction_address;
			end if;
		end if;
	end process get_instruction;

-- Extract register addresses from the instruction word:
	-- Integer rs1 (exclude all FP instructions)
rs1_addr <= instruction(19 downto 15)
  when instruction(6 downto 2) /= b"10100"     
  else (others => '0');

-- Integer rs2
rs2_addr <= instruction(24 downto 20)
  when instruction(6 downto 2) /= b"10100" and
       instruction(6 downto 2) /= b"00001" and
       instruction(6 downto 2) /= b"01001"
  else (others => '0');

-- Integer rd
-- Integer rd
rd_addr <= instruction(11 downto 7)
    when (
        -- Standard Integer Instructions (Exclude OP-FP, FLW, FSW)
        (instruction(6 downto 2) /= b"10100" and -- Not FP Arithmetic
         instruction(6 downto 2) /= b"00001" and -- Not FLW
         instruction(6 downto 2) /= b"01001")    -- Not FSW
    ) or (
        -- Specific FP instructions that write to Integer Registers
        instruction(6 downto 2) = b"10100" and (
            instruction(31 downto 25) = b"1110000" or -- FMV.X.W move from float to int
            instruction(31 downto 25) = b"1010000" or -- FEQ, FLT, FLE
            instruction(31 downto 25) = b"1100000"    -- FCVT.W.S  float to int
       											 )
    	)
    else (others => '0');

-- Integer rd
rd_addr_reg <= instruction(11 downto 7)
    when (
        -- Standard Integer Instructions (Exclude OP-FP, FLW, FSW)
        (instruction(6 downto 2) /= b"10100" and -- Not FP Arithmetic
         instruction(6 downto 2) /= b"00001" and -- Not FLW
         instruction(6 downto 2) /= b"01001")    -- Not FSW
    ) or (
        -- Specific FP instructions that write to Integer Registers
        instruction(6 downto 2) = b"10100" and (
            instruction(31 downto 25) = b"1110000" or -- FMV.X.W
            instruction(31 downto 25) = b"1010000" or -- FEQ, FLT, FLE
            instruction(31 downto 25) = b"1100000"    -- FCVT.W.S
        										)
    )
    else (others => '0');

	---------For floating pont operations------------
		-- Extract register addresses from the instruction word:
	frs1_addr <= instruction(19 downto 15) 
		when instruction(6 downto 2) = b"10100" 
		else (others => '0');  --source register 1
	frs2_addr <= instruction(24 downto 20) 
		when instruction(6 downto 2) = b"10100" 
		or instruction(6 downto 2) = b"01001" 
		else (others => '0');  --source register 2
	frd_addr  <= instruction(11 downto  7) 
		when (instruction(6 downto 2) = b"10100")  -----and instruction(31) = '0')  
		or
    	instruction(6 downto 2) = b"00001" 
		--or (
        ---- Specific FP instructions that write to Integer Registers
        --instruction(6 downto 2) = b"10100" and (
        --    instruction(31 downto 25) /= b"1110000" or -- FMV.X.W
        --    instruction(31 downto 25) /= b"1010000" or -- FEQ, FLT, FLE
        --    instruction(31 downto 25) /= b"1100000"    -- FCVT.W.S
        --										)
		--	)
		else (others => '0');   --destination register
	frd_addr_reg  <= instruction(11 downto  7) 
		when (instruction(6 downto 2) = b"10100")  -----and instruction(31) = '0')  
		or
    	instruction(6 downto 2) = b"00001" 
		or (
        -- Specific FP instructions that write to Integer Registers
        instruction(6 downto 2) = b"10100" and (
            instruction(31) = b"0" or -- FMV.X.W
            instruction(31 downto 25) = b"1101000" or 
            instruction(31 downto 25) = b"1111000"    
        										)
			)
		else (others => '0');   --destination register

	----------------------------------------------------
	-- Extract the shamt value from the instruction word:
	shamt    <= instruction(24 downto 20);

	-- Extract the value specifying which comparison to do in branch instructions:
	funct3 <= instruction(14 downto 12);


	opcode_out <= instruction(6 downto 2);   ----0x53 for floats

	-- Extract the immediate value from the instruction word:
	immediate_decoder: entity work.pp_imm_decoder
		port map(
			instruction => instruction(31 downto 2),
			immediate => immediate_value
			---immediate_fp => immediate_fp_out
		);

	-- CSR address decoding
	decode_csr_addr: process(immediate_value)
	begin
		if immediate_value(11 downto 0) = CSR_EPC_MRET then
			csr_addr <= CSR_MEPC;
		else
			csr_addr <= immediate_value(11 downto 0);
		end if;
	end process decode_csr_addr;

	-- Control unit instance
	control_unit: entity work.pp_control_unit
		port map(
			opcode => instruction(6 downto 2),   --10100 for floats
			funct3 => instruction(14 downto 12), -- rounding modes
			funct7 => instruction(31 downto 25), --0,4,8,12 for floats
			rs2 => instruction(24 downto 20),    -- rs2 field for FCVT variant dispatch
			funct12 => instruction(31 downto 20), --
			rd_write => rd_write_reg,
			frd_write => frd_write_reg,  -- fpu.sv
			branch => branch,
			alu_x_src => alu_x_src,
			alu_y_src => alu_y_src,
			alu_op => alu_op_reg,
			mem_op => mem_op,
			mem_size => mem_size,
			decode_exception => decode_exception,
			decode_exception_cause => decode_exception_cause,
			csr_write => csr_write,
			csr_imm => csr_use_imm
		);
		
    --  delibrate stall because of Stor instruction ---- still in doubt since core also has a stor instruction
insert_nop_proc : process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            insert_nop  <= '0';
            nop_trigger <= '0';
        elsif (stall = '0' and stall_fpu = '0' ) then   ----and stall_fpu = '0'
            if is_csd_op(alu_op_reg) and rd_write_reg = '1' and  rd_addr_reg/=b"00000"  and nop_trigger = '0' then
                insert_nop  <= '1';
                nop_trigger <= '1';
            else 
                insert_nop  <= '0';
                nop_trigger <= '0';
            end if;
		
        end if;
    end if;
end process;
    
    insert_nop_id <= insert_nop;
	decode_valid <= instruction_ready when ((stall_fpu = '0') and (stall = '0')) and flush = '0' else '0'; ---(stall_fpu = '0') or ---when ((stall_fpu = '0') or (stall = '0')) and flush = '0' else '0';
	instruction_out <= instruction;   ----32 bit riscv intruction


	-- DIV Detection (combinational)  only for fpus
	div_detected_out <= '1' when  instruction(6 downto 2) = b"10100" and instruction(31 downto 25) = b"0001100" else '0';  ---and (decode_valid_out = '1')

end architecture behaviour;
