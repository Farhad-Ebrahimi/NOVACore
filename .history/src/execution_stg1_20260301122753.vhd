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
use work.pp_csr.all;
use work.pp_utilities.all;

entity fp_exe_stg1 is
  port (
    clk : in std_logic;
    reset : in std_logic;

    stall, flush : in std_logic;

    -- Interrupt inputs:
    irq : in std_logic_vector(7 downto 0);
    software_interrupt, timer_interrupt : in std_logic;
    instruction_in : in std_logic_vector(31 downto 0);  ---- from decode stage

    rm : in std_logic_vector(2 downto 0);   ---- fpu.sv

    -- Data memory outputs:
    dmem_address : out std_logic_vector(31 downto 0);
    dmem_data_out : out std_logic_vector(31 downto 0);
    --- dmem_fpdata_out : out std_logic_vector(31 downto 0);  ---- fpu 
    dmem_data_size : out std_logic_vector(1 downto 0);
    dmem_read_req : out std_logic;
    dmem_write_req : out std_logic;

    -- Register addresses:
    rs1_addr_in, rd_addr_in : in register_address;
    rd_addr_out : out register_address;

    frs1_addr_in, frd_addr_in : in register_address;     --- for FPU
    frd_addr_out : out register_address;               --- for FPU

    -- registers value
    rd_data_out : out std_logic_vector(31 downto 0);
    --frd_data_out : out std_logic_vector(31 downto 0);  -- FP register data output (for FMV.W.X)

    

    -- Constant values:
    shamt_in : in std_logic_vector(4 downto 0);
    immediate_in : in std_logic_vector(31 downto 0);
    immediate_fp_in : in std_logic_vector(31 downto 0);  -- Immediate for floating-point instructions, coming from

    -- Instruction address:
    pc_in : in std_logic_vector(31 downto 0);
    pc_out : out std_logic_vector(31 downto 0);

    -- Funct3 value from the instruction, used to choose which comparison
    -- is used when branching:
    funct3_in : in std_logic_vector(2 downto 0);

    -- CSR signals:
    csr_addr_in : in csr_address;
    csr_addr_out : out csr_address;
    csr_write_in : in csr_write_mode;
    csr_write_out : out csr_write_mode;
    csr_value_in : in std_logic_vector(31 downto 0);
    csr_value_out : out std_logic_vector(31 downto 0);
    csr_use_immediate_in : in std_logic;

    -- Control signals:
    alu_op_in : in alu_operation;
    alu_op_out : out alu_operation;
    alu_x_src_in : in alu_operand_source;
    alu_y_src_in : in alu_operand_source;
    rd_write_in : in std_logic;
    rd_write_out : out std_logic;
    frd_write_in : in std_logic; ----------------- for FPU
    frd_write_out : out std_logic; --------------- for FPU
    branch_in : in branch_type;
    branch_out : out branch_type;
    internal_stall : in STD_LOGIC;

    -- Memory control signals:
    mem_op_in : in memory_operation_type;
    mem_op_out : out memory_operation_type;
    mem_size_in : in memory_operation_size;
    mem_size_out : out memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_in : in std_logic;
    count_instruction_out : out std_logic;

    -- Exception control registers:
    ie_in, ie1_in : in std_logic;
    mie_in : in std_logic_vector(31 downto 0);
    mtvec_in : in std_logic_vector(31 downto 0);
    mtvec_out : out std_logic_vector(31 downto 0);
    --mepc_in       : in  std_logic_vector(31 downto 0);

    -- Exception signals:
    decode_exception_in : in std_logic;
    decode_exception_cause_in : in csr_exception_cause;

    -- Exception outputs:
    exception_out : out std_logic;
    exception_context_out : out csr_exception_context;

    -- Control outputs:
    jump_out : out std_logic;
    jump_inst : out std_logic;
    jump_target_out : out std_logic_vector(31 downto 0);

    rs1_forwarded : in std_logic_vector(31 downto 0);
    rs2_forwarded : in std_logic_vector(31 downto 0);

    frs1_forwarded : in std_logic_vector(31 downto 0);    ---- for fpu
    frs2_forwarded : in std_logic_vector(31 downto 0);    ---- for fpu


    en_fadd : in std_logic;
    en_fsub : in std_logic;
    en_fmul : in std_logic;
    en_fdiv : in std_logic;

  
    
    -- FPU Stage 1 all 4 operation outputs (for parallel computation in Stage 2)
    -- ADD Stage 1 outputs
    add_A_sign_out : out std_logic;
    add_B_sign_out : out std_logic;
    add_A_exp_out : out std_logic_vector(7 downto 0);
    add_B_exp_out : out std_logic_vector(7 downto 0);
    add_A_mant_out : out std_logic_vector(26 downto 0);
    add_B_mant_out : out std_logic_vector(26 downto 0);
    add_rm_out : out std_logic_vector(2 downto 0);
    add_valid_out : out std_logic;
    
    -- SUB Stage 1 outputs
    sub_A_sign_out : out std_logic;
    sub_B_sign_out : out std_logic;
    sub_A_exp_out : out std_logic_vector(7 downto 0);
    sub_B_exp_out : out std_logic_vector(7 downto 0);
    sub_A_mant_out : out std_logic_vector(26 downto 0);
    sub_B_mant_out : out std_logic_vector(26 downto 0);
    sub_rm_out : out std_logic_vector(2 downto 0);
    
    -- MUL Stage 1 outputs (including fractions)
    mul_A_sign_out : out std_logic;
    mul_B_sign_out : out std_logic;
    mul_A_exp_out : out std_logic_vector(7 downto 0);
    mul_B_exp_out : out std_logic_vector(7 downto 0);
    mul_A_frac_out : out std_logic_vector(22 downto 0);  -- Raw fraction for NaN/Inf detection
    mul_B_frac_out : out std_logic_vector(22 downto 0);
    mul_A_mant_out : out std_logic_vector(26 downto 0);
    mul_B_mant_out : out std_logic_vector(26 downto 0);
    mul_rm_out : out std_logic_vector(2 downto 0);
    
    -- DIV Stage 1 outputs
    div_x_val_out : out std_logic_vector(31 downto 0);
    div_y_val_out : out std_logic_vector(31 downto 0);
    div_exp_out : out std_logic_vector(7 downto 0);
    div_sign_out : out std_logic;
    div_special_out : out std_logic;
    div_special_result_out : out std_logic_vector(31 downto 0);
    div_valid_out : out std_logic;
    div_rm_out : out std_logic_vector(2 downto 0);

    -- Division control signal for FPU Stage 1 divider
    div_start : in std_logic;  ---- from pp_core division control

    -- Division latched operands from pp_core (for divider stability)
    div_op1 : in std_logic_vector(31 downto 0);  ----fpu.sv div latch logic
    div_op2 : in std_logic_vector(31 downto 0);  ----fpu.sv div latch logic
    div_rm : in std_logic_vector(2 downto 0);    ----fpu.sv div latch logic

    x_sign_out : out std_logic_vector(32 downto 0);
    x_data_out : out std_logic_vector(32 downto 0);
    y_sign_out : out std_logic_vector(32 downto 0);
    y_data_out : out std_logic_vector(32 downto 0);
    alu_y_out : out std_logic_vector(31 downto 0)
  );
end entity fp_exe_stg1;

architecture behaviour of fp_exe_stg1 is
  signal alu_op : alu_operation;
  signal alu_x_src, alu_y_src : alu_operand_source;

  signal alu_x, alu_y, alu_result : std_logic_vector(31 downto 0);
  signal alu_x_reg, alu_y_reg: std_logic_vector(31 downto 0);
  signal alu_x_mux_o, alu_y_mux_o: std_logic_vector(31 downto 0);

  signal fp_alu_x, fp_alu_y, fp_alu_result : std_logic_vector(31 downto 0);
  signal fp_alu_x_reg, fp_alu_y_reg: std_logic_vector(31 downto 0);
  signal fp_alu_x_mux_o, fp_alu_y_mux_o: std_logic_vector(31 downto 0);
  
  signal rs1_addr : register_address;
  signal frs1_addr : register_address;   --- for FPU

  signal mem_op : memory_operation_type;
  signal mem_size : memory_operation_size;

  signal frd_data_out : std_logic_vector(31 downto 0);  -- 

  signal pc : std_logic_vector(31 downto 0);
  signal immediate : std_logic_vector(31 downto 0);
  signal immediate_fp : std_logic_vector(31 downto 0);  -- Immediate for floating-
  signal shamt : std_logic_vector(4 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);

  signal branch : branch_type;
  signal branch_condition : std_logic;
  signal fp_branch_condition : std_logic;
  signal do_jump : std_logic;
  signal jump_target : std_logic_vector(31 downto 0);

  signal mie, mtvec : std_logic_vector(31 downto 0);

  signal csr_write : csr_write_mode;
  signal csr_addr : csr_address;
  signal csr_use_immediate : std_logic;

  signal csr_value : std_logic_vector(31 downto 0);

  signal decode_exception : std_logic;
  signal decode_exception_cause : csr_exception_cause;

  signal exception_taken : std_logic;
  signal exception_cause : csr_exception_cause;
  signal exception_addr : std_logic_vector(31 downto 0);

  signal instr_misaligned : std_logic;

  signal irq_asserted : std_logic;
  signal irq_asserted_num : std_logic_vector(3 downto 0);

  signal cmp : unsigned(31 downto 0);
  signal fp_mem_addr : std_logic_vector(31 downto 0);
  signal fp_immediate : std_logic_vector(31 downto 0);
  signal instruction : std_logic_vector(31 downto 0); --- added 2026-02

  signal rs1_conv : std_logic_vector(31 downto 0);  ---f2i
  signal rs1_to_be_convd : std_logic_vector(31 downto 0);
  signal frs1_conv : std_logic_vector(31 downto 0);
  signal frs1_to_be_convd : std_logic_vector(31 downto 0);

  --signal div_start_in : std_logic;

begin

  -- Register values should not be latched in by a clocked process,
  -- this is already done in the register files.

  cmp <= x"AAAAAAAA";

  csr_value <= csr_value_in;


  --rd_data_out <= alu_result;
  
  -- FMV routing: FMV.X.W writes FP register to integer register file
  -- FP comparisons (FEQ.S, FLT.S, FLE.S) write 0/1 result to integer register
  rd_data_out <= frs1_forwarded when alu_op = ALU_FMVXW 
                  else rs1_forwarded when alu_op = ALU_FMVWX  -----int to floats
                  else rs1_conv when alu_op = ALU_FCVT_W or alu_op = ALU_FCVT_WU -----f2i
                  else frs1_conv when alu_op = ALU_FCVT_S_W or alu_op = ALU_FCVT_S_WU  
                  else (31 downto 1 => '0') & fp_branch_condition 
                       when (alu_op = ALU_FEQ or alu_op = ALU_FLT or alu_op = ALU_FLE)
                  else alu_result;
  
  -- FMV.W.X writes integer register to FP register file
  ---frd_data_out <= rs1_forwarded when alu_op_in = ALU_FMVWX else (others => '0');

 

  branch_out <= branch;

  mem_op_out <= mem_op;
  mem_size_out <= mem_size;

  csr_write_out <= csr_write;
  csr_addr_out <= csr_addr;

  pc_out <= pc;
  exception_out <= exception_taken;
  
  


  exception_context_out <= (
    ie => ie_in,
    ie1 => ie1_in,
    cause => exception_cause,
    badaddr => exception_addr);
---------jump not for floats
  do_jump <= (to_std_logic(branch = BRANCH_JUMP or branch = BRANCH_JUMP_INDIRECT)
    or (to_std_logic(branch = BRANCH_CONDITIONAL) and branch_condition)
    or to_std_logic(branch = BRANCH_SRET)) and not stall and not internal_stall; --------internal stall added 
  
  jump_inst <= '1' when (branch /= BRANCH_NONE) else '0';
  
  jump_out <= do_jump;
  jump_target_out <= jump_target;

  mtvec_out <= std_logic_vector(unsigned(mtvec));
  exception_taken <= not stall and not internal_stall and (decode_exception or to_std_logic(exception_cause /= CSR_CAUSE_NONE));   -----not internal stall added

  irq_asserted <= to_std_logic(ie_in = '1' and (irq and mie(31 downto 24)) /= x"00");
  
  dmem_address <= (others => '0');
  dmem_data_out  <= frs2_forwarded when mem_op = MEMOP_TYPE_STORE_FP else rs2_forwarded;
  
  dmem_write_req <= '1' when (mem_op = MEMOP_TYPE_STORE or mem_op = MEMOP_TYPE_STORE_FP) and exception_taken = '0' else '0';
  dmem_read_req <= '1' when memop_is_load(mem_op) and exception_taken = '0' else '0';

  alu_op_out <= alu_op;
  alu_y_out <= alu_y;
  
  alu_x <= alu_x_mux_o when (stall ='0' and internal_stall = '0') else alu_x_reg;   -------internal stall added
  alu_y <= alu_y_mux_o when (stall ='0' and internal_stall = '0') else alu_y_reg;   -------internal stall added


 
  pipeline_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or flush = '1' then
        rd_write_out <= '0';
        frd_write_out <= '0'; ----------------- for FPU
        branch <= BRANCH_NONE;
        csr_write <= CSR_WRITE_NONE;
        mem_op <= MEMOP_TYPE_NONE;
        decode_exception <= '0';
        count_instruction_out <= '0';
      elsif stall = '1' or internal_stall = '1' then
        csr_write <= CSR_WRITE_NONE;
        ----frd_write_out <= '0'; 
      elsif stall = '0' and internal_stall = '0' then   ---or internal_stall = '0'

        pc <= pc_in;
        count_instruction_out <= count_instruction_in;

        instruction <= instruction_in;  --- added 2026-02
        
        -- Register signals:
        rd_write_out <= rd_write_in;
        frd_write_out <= frd_write_in; --------------- for FPU

        rd_addr_out <= rd_addr_in;
        frd_addr_out <= frd_addr_in;             --- for FPU

        rs1_addr <= rs1_addr_in;
        frs1_addr <= frs1_addr_in;          --- for FPU

        -- ALU signals:
        alu_op <= alu_op_in;   ----add or sub or mul or div or etc
        alu_x_src <= alu_x_src_in;
        alu_y_src <= alu_y_src_in;

        alu_x_reg <= alu_x;
        alu_y_reg <= alu_y;


        fp_alu_x_reg <= fp_alu_x;   ------for fpu
        fp_alu_y_reg <= fp_alu_y;    ------ for fpu
        
        -- Control signals:
        branch <= branch_in;
        mem_op <= mem_op_in;
        mem_size <= mem_size_in;

        -- Constant values:
        immediate <= immediate_in;
        immediate_fp <= immediate_fp_in;  
        shamt <= shamt_in;
        funct3 <= funct3_in;

        -- CSR signals:
        csr_write <= csr_write_in;
        csr_addr <= csr_addr_in;
        csr_use_immediate <= csr_use_immediate_in;

        -- Exception vector base:
        mtvec <= mtvec_in;
        mie <= mie_in;
        
        -- Instruction decoder exceptions:
        decode_exception <= decode_exception_in;
        decode_exception_cause <= decode_exception_cause_in;



      end if;
    end if;
end process;


  set_data_size : process (mem_size)
  begin
    case mem_size is
      when MEMOP_SIZE_BYTE =>
        dmem_data_size <= b"01";
      when MEMOP_SIZE_HALFWORD =>
        dmem_data_size <= b"10";
      when MEMOP_SIZE_WORD =>
        dmem_data_size <= b"00";
      when others =>
        dmem_data_size <= b"11";
    end case;
  end process set_data_size;

  get_irq_num : process (irq, mie)
    variable temp : std_logic_vector(3 downto 0);
  begin
    temp := (others => '0');

    for i in 0 to 7 loop
      if irq(i) = '1' and mie(24 + i) = '1' then
        temp := std_logic_vector(to_unsigned(i, temp'length));
        exit;
      end if;
    end loop;

    irq_asserted_num <= temp;
  end process get_irq_num;

  instr_misalign_check : process (jump_target, branch, branch_condition, do_jump)
  begin
    if jump_target(1 downto 0) /= b"00" and do_jump = '1' then
      instr_misaligned <= '1';
    else
      instr_misaligned <= '0';
    end if;
  end process instr_misalign_check;

  find_exception_cause : process (decode_exception, decode_exception_cause, mem_op,
    instr_misaligned, irq_asserted, irq_asserted_num, mie,
    software_interrupt, timer_interrupt, ie_in)
  begin
    if irq_asserted = '1' then
      exception_cause <= std_logic_vector(unsigned(CSR_CAUSE_IRQ_BASE) + unsigned(irq_asserted_num));
    elsif software_interrupt = '1' and mie(CSR_MIE_MSIE) = '1' and ie_in = '1' then
      exception_cause <= CSR_CAUSE_SOFTWARE_INT;
    elsif timer_interrupt = '1' and mie(CSR_MIE_MTIE) = '1' and ie_in = '1' then
      exception_cause <= CSR_CAUSE_TIMER_INT;
    elsif decode_exception = '1' then
      exception_cause <= decode_exception_cause;
    elsif mem_op = MEMOP_TYPE_INVALID then
      exception_cause <= CSR_CAUSE_INVALID_INSTR;
    elsif instr_misaligned = '1' then
      exception_cause <= CSR_CAUSE_INSTR_MISALIGN;
      --	elsif data_misaligned = '1' and mem_op = MEMOP_TYPE_STORE then
      --	exception_cause <= CSR_CAUSE_STORE_MISALIGN;
      --	elsif data_misaligned = '1' and memop_is_load(mem_op) then
      --	exception_cause <= CSR_CAUSE_LOAD_MISALIGN;
    else
      exception_cause <= CSR_CAUSE_NONE;
    end if;
  end process find_exception_cause;

  find_exception_addr : process (instr_misaligned, jump_target)
  begin
    if instr_misaligned = '1' then
      exception_addr <= jump_target;
      --	elsif data_misaligned = '1' then
      --	exception_addr <= alu_result;
    else
      exception_addr <= (others => '0');
    end if;
  end process find_exception_addr;

-------- need to check for floats not yet for floats
  calc_jump_tgt : process (branch, pc, rs1_forwarded, immediate, csr_value)   ----check later
  begin
    case branch is
      when BRANCH_JUMP | BRANCH_CONDITIONAL =>
        jump_target <= std_logic_vector(unsigned(pc) + unsigned(immediate));
      when BRANCH_JUMP_INDIRECT =>
        jump_target <= std_logic_vector(unsigned(rs1_forwarded) + unsigned(immediate));
      when BRANCH_SRET =>
        jump_target <= csr_value;
      when others =>
        jump_target <= (others => '0');
    end case;
  end process calc_jump_tgt;


  alu_x_mux : entity work.pp_alu_mux
    port map(
      source => alu_x_src,
      register_value => rs1_forwarded,
      immediate_value => immediate,
      shamt_value => shamt,
      pc_value => pc,
      csr_value => csr_value,
      output => alu_x_mux_o
    );

  alu_y_mux : entity work.pp_alu_mux
    port map(
      source => alu_y_src,
      register_value => rs2_forwarded,
      immediate_value => immediate,
      shamt_value => shamt,
      pc_value => pc,
      csr_value => csr_value,
      output => alu_y_mux_o
    );



----frs1_to_be_convd <= rs1_forwarded when alu_op = ALU_FCVT_S_W or alu_op = ALU_FCVT_S_WU else (others => '0');  --- 
rs1_to_frs1: entity work.pp_int_2_float
    port map(
        data_in => rs1_forwarded,
        alu_op_in => alu_op,
        frd_data_out => frs1_conv
    );

-----rs1_to_be_convd <= frs1_forwarded when alu_op = ALU_FCVT_W or alu_op = ALU_FCVT_WU else (others => '0');  --- f
frs1_to_rs1: entity work.pp_float_2_int
    port map(
        frd_data_in => frs1_forwarded,
        alu_op_in => alu_op,
        rd_data_out => rs1_conv
    );



  branch_comparator : entity work.pp_comparator
    port map(
      funct3 => funct3,
      rs1 => rs1_forwarded,
      rs2 => rs2_forwarded,
      result => branch_condition
    );


    ---- added for FPU branch comparisons, will check later
  fp_branch_comparator : entity work.fp_pp_comparator   
   port map(
     funct3 => funct3,
     alu_op_in => alu_op,
     frs1 => frs1_forwarded,
     frs2 => frs2_forwarded,
     result => fp_branch_condition
   );


     ---- prob not needed for fpu

  alu_instance : entity work.bw_alu      
    port map(
      result => alu_result,
      x => alu_x,
      y => alu_y,
      operation => alu_op
    );


---- will check later not needed. 
  csr_alu_instance : entity work.pp_csr_alu 
    port map(
      x => csr_value,
      y => rs1_forwarded,
      result => csr_value_out,
      immediate => rs1_addr,
      use_immediate => csr_use_immediate,
      write_mode => csr_write
    );


----- prob not needed for fpu
  Bin2CSD_X_instance : entity work.B2C           
    port map(
      x => alu_x,
      ys => x_sign_out(31 downto 0),
      yd => x_data_out(31 downto 0)
    );

  mulhu_x : process (alu_op, alu_x,alu_y, cmp)  ----- pro not needed for fpu
  begin
    x_sign_out(32) <= '0';
    x_data_out(32) <= '0';
    if (alu_op = ALU_MULHU and unsigned(alu_y) > cmp) then
      x_data_out(32) <= '1';
    end if;
  end process;
  
 ----- pro not needed for fpu
  Bin2CSD_Y_instance : entity work.B2C    
    port map(
      x => alu_y,
      ys => y_sign_out(31 downto 0),
      yd => y_data_out(31 downto 0)
    );

  mulhu_y : process (alu_op, alu_y, cmp)     ----- pro not needed for fpu
  begin
    y_sign_out(32) <= '0';
    y_data_out(32) <= '0';
    if ((alu_op = ALU_MULHU or alu_op = ALU_MULHSU) and unsigned(alu_y) > cmp) then
      y_data_out(32) <= '1';
    end if;
  end process;
 
  -- FPU Stage 1 instantiation
  fpu_stg1_instance : entity work.fpu_stage1
    port map(
      clk => clk,
      reset => reset,
      stall => internal_stall,
      stall_ex => stall,  

      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,

      start => div_start,  ----fpu.sv div latch logic
      
      operand1 => frs1_forwarded,
      operand2 => frs2_forwarded,

      ------rm => instruction_in(14 downto 12),
      rm => rm,    -----added to mirror fpu.sv
      div_operand1 => div_op1,   ----fpu.sv div latch logic
      div_operand2 => div_op2,   ----fpu.sv div latch logic
      div_rm_in => div_rm,       ----fpu.sv div latch logic
      
      -- ADD Stage 1 outputs
      add_A_sign => add_A_sign_out,
      add_B_sign => add_B_sign_out,
      add_A_exp => add_A_exp_out,
      add_B_exp => add_B_exp_out,
      add_A_mant => add_A_mant_out,
      add_B_mant => add_B_mant_out,
      add_rm => add_rm_out,
      add_valid => add_valid_out,  -----add)valid_out need to add
      
      -- SUB Stage 1 outputs
      sub_A_sign => sub_A_sign_out,
      sub_B_sign => sub_B_sign_out,
      sub_A_exp => sub_A_exp_out,
      sub_B_exp => sub_B_exp_out,
      sub_A_mant => sub_A_mant_out,
      sub_B_mant => sub_B_mant_out,
      sub_rm => sub_rm_out,
      
      -- MUL Stage 1 outputs
      mul_A_sign => mul_A_sign_out,
      mul_B_sign => mul_B_sign_out,
      mul_A_exp => mul_A_exp_out,
      mul_B_exp => mul_B_exp_out,
      mul_A_frac => mul_A_frac_out,
      mul_B_frac => mul_B_frac_out,
      mul_A_mant => mul_A_mant_out,
      mul_B_mant => mul_B_mant_out,
      mul_rm => mul_rm_out,
      
      -- DIV Stage 1 outputs
      div_x_val => div_x_val_out,
      div_y_val => div_y_val_out,
      div_exp => div_exp_out,
      div_sign => div_sign_out,
      div_special => div_special_out,
      div_special_result => div_special_result_out,
      div_valid => div_valid_out,   ----important
      div_rm => div_rm_out
    );

end architecture behaviour;