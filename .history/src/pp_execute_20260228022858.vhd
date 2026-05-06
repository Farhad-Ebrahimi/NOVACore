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

entity pp_execute is
  port (
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    flush : in STD_LOGIC;
    
    stall_exe_stg1 : in STD_LOGIC;
    stall_exe_stg2 : in STD_LOGIC;

    internal_stall : in STD_LOGIC;

    -- Interrupt inputs:
    irq : in STD_LOGIC_VECTOR(7 downto 0);
    software_interrupt : in STD_LOGIC;
    timer_interrupt : in STD_LOGIC;

    -- Data memory outputs:  ----- dont interfere with fpu.sv need to verify   ------for flw and fsw
    dmem_address : out STD_LOGIC_VECTOR(31 downto 0);
    dmem_data_out : out STD_LOGIC_VECTOR(31 downto 0);
    dmem_data_size : out STD_LOGIC_VECTOR(1 downto 0);
    dmem_read_req : out STD_LOGIC;
    dmem_write_req : out STD_LOGIC;

    -- Register addresses:
    rs1_addr_in, rs2_addr_in, rd_addr_in : in register_address;
    rd_addr_out : out register_address;

    -- fpu register addresses :  means which register out of 32
    frs1_addr_in, frs2_addr_in, frd_addr_in : in register_address;   ----source and dest registers coming from decode
    frd_addr_out : out register_address;

    -- Register values:
    rs1_data_in, rs2_data_in : in STD_LOGIC_VECTOR(31 downto 0);
    rd_data_out : out STD_LOGIC_VECTOR(31 downto 0);

    -- FPU Register values:
    frs1_data_in, frs2_data_in : in STD_LOGIC_VECTOR(31 downto 0);   ----- values from registers
    frd_data_out : out STD_LOGIC_VECTOR(31 downto 0);    -----final output from stage 3 


    -- Constant values:
    shamt_in : in STD_LOGIC_VECTOR(4 downto 0);
    immediate_in : in STD_LOGIC_VECTOR(31 downto 0);

    -- Instruction address:
    pc_in : in STD_LOGIC_VECTOR(31 downto 0);
    pc_out : out STD_LOGIC_VECTOR(31 downto 0);

    -- Funct3 value from the instruction, used to choose which comparison
    -- is used when branching:
    funct3_in : in STD_LOGIC_VECTOR(2 downto 0);

    ----------------------------------------------
    ----fpu.sv signals

    div_start : in STD_LOGIC;
    div_done : out STD_LOGIC;
    div_busy_out : out STD_LOGIC;     ---- calculated at the end of div stage3
    div_op1 : in STD_LOGIC_VECTOR(31 downto 0);
    div_op2 : in STD_LOGIC_VECTOR(31 downto 0);
    div_rm : in STD_LOGIC_VECTOR(2 downto 0);
    div_rd : in register_address;
    instruction_in : in std_logic_vector(31 downto 0); ---- from decode stage
    opcode_in : in std_logic_vector(4 downto 0); --- from decode stage
    valid_in : in std_logic;   --- from decode stage
    valid_out : out std_logic; 
   ---------------------------------------------

    -- CSR signals:
    csr_addr_in : in csr_address;
    csr_addr_out : out csr_address;
    csr_write_in : in csr_write_mode;
    csr_write_out : out csr_write_mode;
    csr_value_in : in STD_LOGIC_VECTOR(31 downto 0);
    csr_value_out : out STD_LOGIC_VECTOR(31 downto 0);
    csr_use_immediate_in : in STD_LOGIC;

    -- Control signals:
    alu_op_in : in alu_operation;    ------------------coming from decode.vhd
    alu_x_src_in : in alu_operand_source;
    alu_y_src_in : in alu_operand_source;

    rd_write_in : in STD_LOGIC;
    rd_write_out : out STD_LOGIC;

    frd_write_in : in STD_LOGIC;   ---- for FPU
    frd_write_out : out STD_LOGIC;  ---- for FPU

    branch_in : in branch_type;
    branch_out : out branch_type;

    -- Memory control signals:
    mem_op_in : in memory_operation_type;
    mem_op_out : out memory_operation_type;
    mem_size_in : in memory_operation_size;
    mem_size_out : out memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_in : in STD_LOGIC;
    count_instruction_out : out STD_LOGIC;

    -- Exception control registers:
    ie_in, ie1_in : in STD_LOGIC;
    mie_in : in STD_LOGIC_VECTOR(31 downto 0);
    mtvec_in : in STD_LOGIC_VECTOR(31 downto 0);
    mtvec_out : out STD_LOGIC_VECTOR(31 downto 0);

    --mepc_in       : in  std_logic_vector(31 downto 0);

    -- Exception signals:
    decode_exception_in : in STD_LOGIC;
    decode_exception_cause_in : in csr_exception_cause;

    -- Exception outputs to IF:
    exception_out_if : out STD_LOGIC;
    exception_context_out_if : out csr_exception_context;

    -- Exception outputs to MEM:
    exception_out_mem : out STD_LOGIC;
    exception_context_out_mem : out csr_exception_context;

    -- Control outputs:
    jump_out : out STD_LOGIC;
    jump_inst : out STD_LOGIC;
    pcie_bpu : out STD_LOGIC_VECTOR(31 downto 0);
    jump_target_out : out STD_LOGIC_VECTOR(31 downto 0);

    -- Inputs to the forwarding logic from the MEM stage:
    mem_rd_write : in STD_LOGIC;
    mem_rd_addr : in register_address;
    mem_rd_value : in STD_LOGIC_VECTOR(31 downto 0);
--------------------------------------------------------------------------
    mem_frd_write : in STD_LOGIC;
    mem_frd_addr : in register_address;
    mem_frd_value : in STD_LOGIC_VECTOR(31 downto 0);
 
    mem_csr_addr : in csr_address;
    mem_csr_write : in csr_write_mode;
    mem_exception : in STD_LOGIC;
--------------------------------------------------------------------------------
    -- Inputs to the forwarding logic from the WB stage:
    wb_rd_write : in STD_LOGIC;
    wb_rd_addr : in register_address;
    wb_rd_value : in STD_LOGIC_VECTOR(31 downto 0);

    -- Enable signals for power gating (monitoring)--- not used
    en_fadd : buffer std_logic;
    en_fsub : buffer std_logic;
    en_fmul : buffer std_logic;
    en_fdiv : buffer std_logic;


    wb_frd_write : in STD_LOGIC;
    wb_frd_addr : in register_address;
    wb_frd_value : in STD_LOGIC_VECTOR(31 downto 0);
    
    wb_csr_addr : in csr_address;
    wb_csr_write : in csr_write_mode;
    wb_exception : in STD_LOGIC;


    immediate_fp_in : in std_logic_vector(31 downto 0);  -- Immediate for floating-point instructions, coming from decode stage

-------------------------------------------------------------------------------------------------
    -- Hazard detection unit signals:
    mem_mem_op : in memory_operation_type;
    hazard_detected : out STD_LOGIC
  );
end entity pp_execute;

architecture behaviour of pp_execute is

  ----signal alu_op               : alu_operation;
  signal alu_x_src, alu_y_src : alu_operand_source;

  --signal alu_x, alu_y, alu_result : std_logic_vector(31 downto 0);

  signal rs1_addr, rs2_addr, rd_addr : register_address;
  signal rs1_data, rs2_data : STD_LOGIC_VECTOR(31 downto 0);

  signal frs1_addr, frs2_addr, frd_addr : register_address;    --- for fpu
  signal frs1_data, frs2_data : STD_LOGIC_VECTOR(31 downto 0);  --- for fpu


  signal load_hazard_detected, csr_hazard_detected : STD_LOGIC;

  signal rs1_forwarded, rs2_forwarded : STD_LOGIC_VECTOR(31 downto 0);
  signal rs1_forwarded_reg, rs2_forwarded_reg : STD_LOGIC_VECTOR(31 downto 0);


  signal frs1_forwarded, frs2_forwarded : STD_LOGIC_VECTOR(31 downto 0);  --- for fpu
  signal frs1_forwarded_reg, frs2_forwarded_reg : STD_LOGIC_VECTOR(31 downto 0); --- for fpu

  signal csd_instruction_hazard : STD_LOGIC;

  signal mem_op_to_hazard_stg3 : memory_operation_type;

  ------------------------------------------------------------------
  signal rd_addr_to_forwarding_stg3 : register_address;
  signal rd_write_to_forwarding_stg3 : STD_LOGIC;

  signal frd_addr_to_forwarding_stg3 : register_address;  ----fpu.sv
  signal frd_write_to_forwarding_stg3 : STD_LOGIC;    -----fpu.sv
 
  signal bw_to_forwarding_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  

  signal alu_op_to_forwarding_stg3 : alu_operation;
  signal csr_write_to_hazard_stg3 : csr_write_mode;
  signal exception_to_hazard_stg3 : STD_LOGIC;

  signal rm : std_logic_vector(2 downto 0);   ---- fpu.sv

  
  

  -- output signals exe_stg1 to exe_stg2 --

  signal dmem_address_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);
  signal dmem_data_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);
  signal dmem_data_size_to_stg2 : STD_LOGIC_VECTOR(1 downto 0);
  signal dmem_read_req_to_stg2 : STD_LOGIC;
  signal dmem_write_req_to_stg2 : STD_LOGIC;

  -- Register addresses:
  signal rd_addr_to_stg2 : register_address;
  signal frd_addr_to_stg2 : register_address; -----fpu.sv

  -- Register values:
  signal rd_data_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);
  signal frd_data_to_stg2 : STD_LOGIC_VECTOR(31 downto 0); -----fpu.sv

 
  
  -- Stage 1 all 4 FPU operations (parallel computation)
  signal add_A_sign_to_stg2 : std_logic;   ------output of fpu_stg1 and input to fpu_stg2
  signal add_B_sign_to_stg2 : std_logic;   ------output of fpu_stg1 and input to fpu_stg2
  signal add_A_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal add_B_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal add_A_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal add_B_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal add_rm_to_stg2 : std_logic_vector(2 downto 0);
  
  signal sub_A_sign_to_stg2 : std_logic;
  signal sub_B_sign_to_stg2 : std_logic;
  signal sub_A_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal sub_B_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal sub_A_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal sub_B_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal sub_rm_to_stg2 : std_logic_vector(2 downto 0);
  
  signal mul_A_sign_to_stg2 : std_logic;
  signal mul_B_sign_to_stg2 : std_logic;
  signal mul_A_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal mul_B_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal mul_A_frac_to_stg2 : std_logic_vector(22 downto 0);
  signal mul_B_frac_to_stg2 : std_logic_vector(22 downto 0);
  signal mul_A_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal mul_B_mant_to_stg2 : std_logic_vector(26 downto 0);
  signal mul_rm_to_stg2 : std_logic_vector(2 downto 0);
  
  signal div_x_val_to_stg2 : std_logic_vector(31 downto 0);
  signal div_y_val_to_stg2 : std_logic_vector(31 downto 0);
  signal div_exp_to_stg2 : std_logic_vector(7 downto 0);
  signal div_sign_to_stg2 : std_logic;
  signal div_special_to_stg2 : std_logic;
  signal div_special_result_to_stg2 : std_logic_vector(31 downto 0);
  signal div_valid_to_stg2 : std_logic;

  signal div_valid_to_stg2_out_stg1 : std_logic;


  signal add_valid_out_s1 : std_logic;  
  signal add_valid_out_s2 : std_logic;

  -- Instruction address:
  signal pc_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);

  -- CSR signals:
  signal csr_addr_to_stg2 : csr_address;
  signal csr_write_to_stg2 : csr_write_mode;
  signal csr_value_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);

  -- Control signals:
  signal alu_op_to_stg2 : alu_operation;

  signal rd_write_to_stg2 : std_logic;
  signal frd_write_to_stg2 : std_logic;   ---- fpu.sv

  signal branch_to_stg2 : branch_type;

  -- Memory control signals:
  signal mem_op_to_stg2 : memory_operation_type;
  signal mem_size_to_stg2 : memory_operation_size;

  -- Whether the instruction should be counted:
  signal count_instruction_to_stg2 : STD_LOGIC;

  -- Exception control registers:
  signal mtvec_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);

  -- Exception outputs:
  signal exception_to_stg2 : STD_LOGIC;
  signal exception_context_to_stg2 : csr_exception_context;

  -- csd alu inputs
  signal x_sign_to_stg2 : STD_LOGIC_VECTOR(32 downto 0);
  signal x_data_to_stg2 : STD_LOGIC_VECTOR(32 downto 0);
  signal y_sign_to_stg2 : STD_LOGIC_VECTOR(32 downto 0);
  signal y_data_to_stg2 : STD_LOGIC_VECTOR(32 downto 0);
  signal alu_y_to_stg2 : STD_LOGIC_VECTOR(31 downto 0);

  -- output signals exe_stg2 to exe_stg3 --

  signal dmem_address_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  signal dmem_data_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  signal dmem_data_size_to_stg3 : STD_LOGIC_VECTOR(1 downto 0);
  signal dmem_read_req_to_stg3 : STD_LOGIC;
  signal dmem_write_req_to_stg3 : STD_LOGIC;

  -- Register addresses:
  signal rd_addr_to_stg3 : register_address;
  signal frd_addr_to_stg3 : register_address;   ---- fpu.sv

  -- Register values:
  signal bw_alu_result_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  signal fp_bw_alu_result_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);   ---- fpu.sv    ----need to check
  signal Pst_result_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  signal Ngt_result_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);
  

  signal W1_to_stg3 : STD_LOGIC_VECTOR(83 downto 0);
  signal W2_to_stg3 : STD_LOGIC_VECTOR(83 downto 0);
  signal W3_to_stg3 : STD_LOGIC_VECTOR(83 downto 0);
  signal W4_to_stg3 : STD_LOGIC_VECTOR(83 downto 0);
  signal Lpp_to_stg3 : STD_LOGIC_VECTOR(67 downto 0);
  
  -- FPU Stage 2 all 4 operations outputs (to Stage 3)
  signal add_out_sign_to_stg3 : std_logic;
  signal add_out_exp_to_stg3 : std_logic_vector(7 downto 0);
  signal add_out_mant_to_stg3 : std_logic_vector(27 downto 0);
  signal add_out_rm_to_stg3 : std_logic_vector(2 downto 0);
  
  signal sub_out_sign_to_stg3 : std_logic;
  signal sub_out_exp_to_stg3 : std_logic_vector(7 downto 0);
  signal sub_out_mant_to_stg3 : std_logic_vector(27 downto 0);
  signal sub_out_rm_to_stg3 : std_logic_vector(2 downto 0);
  
  signal mul_product_to_stg3 : std_logic_vector(47 downto 0);
  signal mul_exp_sum_to_stg3 : std_logic_vector(7 downto 0);
  signal mul_sign_out_to_stg3 : std_logic;
  signal mul_a_is_nan_to_stg3 : std_logic;
  signal mul_b_is_nan_to_stg3 : std_logic;
  signal mul_a_is_inf_to_stg3 : std_logic;
  signal mul_b_is_inf_to_stg3 : std_logic;
  signal mul_a_is_zero_to_stg3 : std_logic;
  signal mul_b_is_zero_to_stg3 : std_logic;
  signal mul_out_rm_to_stg3 : std_logic_vector(2 downto 0);
  
  signal div_quotient_to_stg3 : std_logic_vector(31 downto 0);
  signal div_sticky_to_stg3 : std_logic;
  signal div_out_exp_to_stg3 : std_logic_vector(7 downto 0);
  signal div_out_sign_to_stg3 : std_logic;
  signal div_out_special_to_stg3 : std_logic;
  signal div_out_special_result_to_stg3 : std_logic_vector(31 downto 0);
  signal div_out_valid_to_stg3 : std_logic;
  signal div_busy_to_stg3 : std_logic;
  signal div_out_rm_to_stg3 : std_logic_vector(2 downto 0);

  -- Instruction address:
  signal pc_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);

  -- CSR signals:
  signal csr_addr_to_stg3 : csr_address;
  signal csr_write_to_stg3 : csr_write_mode;
  signal csr_value_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);

  -- Control signals:
  signal alu_op_to_stg3 : alu_operation;

  signal rd_write_to_stg3 : STD_LOGIC;
  signal frd_write_to_stg3 : STD_LOGIC;   ---- fpu.sv

  signal branch_to_stg3 : branch_type;

  
  -- Memory control signals:
  signal mem_op_to_stg3 : memory_operation_type;
  signal mem_size_to_stg3 : memory_operation_size;

  -- Whether the instruction should be counted:
  signal count_instruction_to_stg3 : STD_LOGIC;

  -- Exception control registers:
  signal mtvec_to_stg3 : STD_LOGIC_VECTOR(31 downto 0);

  -- Exception outputs:
  signal exception_to_stg3 : STD_LOGIC;
  signal exception_context_to_stg3 : csr_exception_context;
  
  -- ----fpu.sv div latch logic: Division latched operands from pp_core
  signal div_op1_to_stg1 : std_logic_vector(31 downto 0);
  signal div_op2_to_stg1 : std_logic_vector(31 downto 0);
  signal div_rm_to_stg1 : std_logic_vector(2 downto 0);
  signal div_rm_to_stg2 : std_logic_vector(2 downto 0);
  --signal div_rm_to_stg3 : std_logic_vector(2 downto 0);


  signal add_result_int        : std_logic_vector(31 downto 0);
signal sub_result_int        : std_logic_vector(31 downto 0);
signal mul_result_int        : std_logic_vector(31 downto 0);
signal div_result_int        : std_logic_vector(31 downto 0);


-------------------------------------------------------------------
  

  signal frd_data_stg3 : std_logic_vector(31 downto 0);
  
  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of exception_out_if: signal is "TRUE";

begin

  rs1_data <= rs1_data_in;
  rs2_data <= rs2_data_in;


  frs1_data <= frs1_data_in;   ---- for fpu
  frs2_data <= frs2_data_in;   ---- for fpu
  
  -- Division RM signal forwarding to Stage 2
  div_rm_to_stg2 <= div_rm;

 

 -- -- TEMPORARY: Direct forwarding of FP register data (should come from forwarding logic)
 -- frs1_forwarded <= frs1_data;  ---- for fpu (NEEDS forwarding logic)
 -- frs2_forwarded <= frs2_data;  ---- for fpu (NEEDS forwarding logic)
--

  mem_op_out <= mem_op_to_hazard_stg3;

  rd_addr_out <= rd_addr_to_forwarding_stg3;
  frd_addr_out <= frd_addr_to_forwarding_stg3;     -----output of execute stage destination register
  
  frd_write_out <= frd_write_to_forwarding_stg3;   ---- fpu.sv  -----output of execute stage write enable
  rd_write_out <= rd_write_to_forwarding_stg3;
  
  csr_write_out <= csr_write_to_hazard_stg3;
  exception_out_mem <= exception_to_hazard_stg3;

  
frd_data_out <= frd_data_stg3; 
rm <= instruction_in(14 downto 12) when valid_in = '1' else "000";

  update_address : process (clk)
  begin
    if rising_edge(clk) then

      if stall_exe_stg1 = '0' and internal_stall = '0' then   -----internal stall added
        rs1_addr <= rs1_addr_in;
        rs2_addr <= rs2_addr_in;
        frs1_addr <= frs1_addr_in;  ---- for fpu
        frs2_addr <= frs2_addr_in;   ---- for fpu
        alu_x_src <= alu_x_src_in;
        alu_y_src <= alu_y_src_in;
        rs1_forwarded_reg <= rs1_forwarded;
        rs2_forwarded_reg <= rs2_forwarded;
        frs1_forwarded_reg <= frs1_forwarded; --- for fpu
        frs2_forwarded_reg <= frs2_forwarded; --- for fpu
        
      end if;
    end if;
  end process update_address;


  -- Enable signals for power-efficient operation gating 
   en_fadd <= '1' when alu_op_in = ALU_FADD else '0';
   en_fsub <= '1' when alu_op_in = ALU_FSUB else '0';
   en_fmul <= '1' when alu_op_in = ALU_FMUL else '0';
   en_fdiv <= '1' when alu_op_in = ALU_FDIV else '0';




  exe_stg1_instance : entity work.fp_exe_stg1
    port map(
      clk => clk,
      reset => reset,
      internal_stall => internal_stall,
      stall => stall_exe_stg1 , 
      flush => flush,
      rm => rm,
      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,

      -- Interrupt inputs:
      irq => irq,
      software_interrupt => software_interrupt,
      timer_interrupt => timer_interrupt,

      -- Data memory outputs:
      dmem_address => dmem_address_to_stg2,
      dmem_data_out => dmem_data_to_stg2,
      dmem_data_size => dmem_data_size_to_stg2,
      dmem_read_req => dmem_read_req_to_stg2,
      dmem_write_req => dmem_write_req_to_stg2,

      rs1_forwarded => rs1_forwarded,
      rs2_forwarded => rs2_forwarded,

      ---these are the inputs into fpu_stg1 
      frs1_forwarded => frs1_forwarded,  ---- for fpu  
      frs2_forwarded => frs2_forwarded,  ---- for fpu

      instruction_in => instruction_in, ---- from decode stage

      x_sign_out => x_sign_to_stg2,
      x_data_out => x_data_to_stg2,
      y_sign_out => y_sign_to_stg2,
      y_data_out => y_data_to_stg2,
      alu_y_out => alu_y_to_stg2,

      -- Register addresses:
      rd_addr_in => rd_addr_in,
      frd_addr_in => frd_addr_in,    ------fpu.sv 1 addr

      rd_addr_out => rd_addr_to_stg2,
      frd_addr_out => frd_addr_to_stg2,   -----fpu.sv 2 addr

      -- Register values:
      rs1_addr_in => rs1_addr_in,
      frs1_addr_in => frs1_addr_in,   ---- fpu.sv 1 addr

      rd_data_out => rd_data_to_stg2,
      
      
      
      -- Constant values:
      shamt_in => shamt_in,
      immediate_in => immediate_in,
      immediate_fp_in => immediate_fp_in,  -- Immediate for floating-point 

      -- Instruction address:
      pc_in => pc_in,
      pc_out => pc_to_stg2,

      -- Funct3 value from the instruction, used to choose which comparison
      -- is used when branching:
      funct3_in => funct3_in,

      -- CSR signals:
      csr_addr_in => csr_addr_in,
      csr_addr_out => csr_addr_to_stg2,
      csr_write_in => csr_write_in,
      csr_write_out => csr_write_to_stg2,
      csr_value_in => csr_value_in,
      csr_value_out => csr_value_to_stg2,
      csr_use_immediate_in => csr_use_immediate_in,

      -- Control signals:
      alu_op_in => alu_op_in,
      alu_op_out => alu_op_to_stg2,
      alu_x_src_in => alu_x_src_in,
      alu_y_src_in => alu_y_src_in,
      rd_write_in => rd_write_in,
      frd_write_in => frd_write_in,  ---- fpu.sv
      rd_write_out => rd_write_to_stg2,
      frd_write_out => frd_write_to_stg2, ---- fpu.sv
      branch_in => branch_in,
      branch_out => branch_to_stg2,

      -- Memory control signals:
      mem_op_in => mem_op_in,
      mem_op_out => mem_op_to_stg2,
      mem_size_in => mem_size_in,
      mem_size_out => mem_size_to_stg2,

      -- Whether the instruction should be counted:
      count_instruction_in => count_instruction_in,
      count_instruction_out => count_instruction_to_stg2,

      -- Exception control registers:
      ie_in => ie_in,
      ie1_in => ie1_in,
      mie_in => mie_in,
      mtvec_in => mtvec_in,
      mtvec_out => mtvec_to_stg2,
      --mepc_in       : in  std_logic_vector(31 downto 0);

      -- Exception signals:
      decode_exception_in => decode_exception_in,
      decode_exception_cause_in => decode_exception_cause_in,

      -- Exception outputs:
      exception_out => exception_to_stg2,
      exception_context_out => exception_context_to_stg2,

      -- Division control signal
      div_start => div_start,

      -- Division latched operands from pp_core ----fpu.sv div latch logic
      div_op1 => div_op1,
      div_op2 => div_op2,
      div_rm => div_rm,

      -- Control outputs:
      jump_out => jump_out,
      jump_inst => jump_inst,
      jump_target_out => jump_target_out,
      
      -- FPU Stage 1 all 4 operations outputs (for Stage 2)

      ----will go inside fpu_stg2
      add_A_sign_out => add_A_sign_to_stg2,  
      add_B_sign_out => add_B_sign_to_stg2,
      add_A_exp_out => add_A_exp_to_stg2,
      add_B_exp_out => add_B_exp_to_stg2,
      add_A_mant_out => add_A_mant_to_stg2,
      add_B_mant_out => add_B_mant_to_stg2,
      add_rm_out => add_rm_to_stg2,
      add_valid_out => add_valid_out_s1,
      
      sub_A_sign_out => sub_A_sign_to_stg2,
      sub_B_sign_out => sub_B_sign_to_stg2,
      sub_A_exp_out => sub_A_exp_to_stg2,
      sub_B_exp_out => sub_B_exp_to_stg2,
      sub_A_mant_out => sub_A_mant_to_stg2,
      sub_B_mant_out => sub_B_mant_to_stg2,
      sub_rm_out => sub_rm_to_stg2,
      
      mul_A_sign_out => mul_A_sign_to_stg2,
      mul_B_sign_out => mul_B_sign_to_stg2,
      mul_A_exp_out => mul_A_exp_to_stg2,
      mul_B_exp_out => mul_B_exp_to_stg2,
      mul_A_frac_out => mul_A_frac_to_stg2,
      mul_B_frac_out => mul_B_frac_to_stg2,
      mul_A_mant_out => mul_A_mant_to_stg2,
      mul_B_mant_out => mul_B_mant_to_stg2,
      mul_rm_out => mul_rm_to_stg2,
      
      div_x_val_out => div_x_val_to_stg2,
      div_y_val_out => div_y_val_to_stg2,
      div_exp_out => div_exp_to_stg2,
      div_sign_out => div_sign_to_stg2,
      div_special_out => div_special_to_stg2,
      div_special_result_out => div_special_result_to_stg2,
      div_valid_out => div_valid_to_stg2
    );

  pcie_bpu <= pc_to_stg2;
  exception_out_if <= exception_to_stg2;
  exception_context_out_if <= exception_context_to_stg2;

  ------div_valid_to_stg2_out_stg1 <= div_valid_out;

  exe_stg2_instance : entity work.fp_exe_stg2
    port map(
      clk => clk,
      reset => reset,
      stall => stall_exe_stg2 ,
      internal_stall => internal_stall,


      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,

      -- Data memory outputs:
      x_sign_in => x_sign_to_stg2,
      x_data_in => x_data_to_stg2,
      y_sign_in => y_sign_to_stg2,
      y_data_in => y_data_to_stg2,

      instruction_in => instruction_in,  --- from decode stage

      -- rd_data_forwarded_x = >,
      -- rd_data_forwarded_y = >,

      -- Data memory outputs:
      dmem_address_in => dmem_address_to_stg2,
      dmem_data_in => dmem_data_to_stg2,
      dmem_data_size_in => dmem_data_size_to_stg2,
      dmem_read_req_in => dmem_read_req_to_stg2,
      dmem_write_req_in => dmem_write_req_to_stg2,

      -- Register addresses:
      rd_addr_in => rd_addr_to_stg2,
      frd_addr_in => frd_addr_to_stg2,   ----fpu.sv

      -- Register values:
      rd_data_in => rd_data_to_stg2,
      --frd_data_in => frd_data_to_stg2,   ----fpu.sv   --- just passed into stage 3 needs to be removed

      -- Instruction address:
      pc_in => pc_to_stg2,

      -- FPU Stage 1 all 4 operations inputs (for parallel computation)
      add_A_sign_in => add_A_sign_to_stg2,
      add_B_sign_in => add_B_sign_to_stg2,
      add_A_exp_in => add_A_exp_to_stg2,
      add_B_exp_in => add_B_exp_to_stg2,
      add_A_mant_in => add_A_mant_to_stg2,
      add_B_mant_in => add_B_mant_to_stg2,
      add_rm_in => add_rm_to_stg2,
      add_valid_in => add_valid_out_s1,
      
      sub_A_sign_in => sub_A_sign_to_stg2,
      sub_B_sign_in => sub_B_sign_to_stg2,
      sub_A_exp_in => sub_A_exp_to_stg2,
      sub_B_exp_in => sub_B_exp_to_stg2,
      sub_A_mant_in => sub_A_mant_to_stg2,
      sub_B_mant_in => sub_B_mant_to_stg2,
      sub_rm_in => sub_rm_to_stg2,
      
      mul_A_sign_in => mul_A_sign_to_stg2,
      mul_B_sign_in => mul_B_sign_to_stg2,
      mul_A_exp_in => mul_A_exp_to_stg2,
      mul_B_exp_in => mul_B_exp_to_stg2,
      mul_A_frac_in => mul_A_frac_to_stg2,
      mul_B_frac_in => mul_B_frac_to_stg2,
      mul_A_mant_in => mul_A_mant_to_stg2,
      mul_B_mant_in => mul_B_mant_to_stg2,
      mul_rm_in => mul_rm_to_stg2,
      
      div_x_val_in => div_x_val_to_stg2,
      div_y_val_in => div_y_val_to_stg2,
      div_exp_in => div_exp_to_stg2,
      div_sign_in => div_sign_to_stg2,
      div_special_in => div_special_to_stg2,
      div_special_result_in => div_special_result_to_stg2,
      div_valid_in => div_valid_to_stg2,
      div_rm_in => div_rm_to_stg2,

      -- CSR signals:
      csr_addr_in => csr_addr_to_stg2,
      csr_write_in => csr_write_to_stg2,
      csr_value_in => csr_value_to_stg2,

      -- csd alu inputs
      alu_op_in => alu_op_to_stg2,
      alu_y_in => alu_y_to_stg2,

      -- Control signals:
      rd_write_in => rd_write_to_stg2,
      frd_write_in => frd_write_to_stg2,  ---- fpu.sv
      branch_in => branch_to_stg2,

      -- Memory control signals:
      mem_op_in => mem_op_to_stg2,
      mem_size_in => mem_size_to_stg2,

      -- Whether the instruction should be counted:
      count_instruction_in => count_instruction_to_stg2,

      -- Exception control registers:
      mtvec_in => mtvec_to_stg2,

      -- Exception outputs:
      exception_in => exception_to_stg2,
      exception_context_in => exception_context_to_stg2,

      -- Data memory outputs:
      dmem_address_out => dmem_address_to_stg3,
      dmem_data_out => dmem_data_to_stg3,
      dmem_data_size_out => dmem_data_size_to_stg3,
      dmem_read_req_out => dmem_read_req_to_stg3,
      dmem_write_req_out => dmem_write_req_to_stg3,

      -- Register addresses:
      rd_addr_out => rd_addr_to_stg3,
      frd_addr_out => frd_addr_to_stg3,   ----fpu.sv

      -- Register values:
      rd_data_out => bw_alu_result_to_stg3,
      

      Pst_result => Pst_result_to_stg3,
      Ngt_result => Ngt_result_to_stg3,

      W1_out => W1_to_stg3,
      W2_out => W2_to_stg3,
      W3_out => W3_to_stg3,
      W4_out => W4_to_stg3,
      Lpp_out => Lpp_to_stg3,
      
      -- FPU Stage 2 all 4 operations outputs (for downstream muxing)
      ----- goes into fpu_stg3
      add_out_sign => add_out_sign_to_stg3,
      add_out_exp => add_out_exp_to_stg3,
      add_out_mant => add_out_mant_to_stg3,
      add_out_rm => add_out_rm_to_stg3,
      add_out_valid => add_valid_out_s2,
      
      sub_out_sign => sub_out_sign_to_stg3,
      sub_out_exp => sub_out_exp_to_stg3,
      sub_out_mant => sub_out_mant_to_stg3,
      sub_out_rm => sub_out_rm_to_stg3,
      
      mul_product => mul_product_to_stg3,
      mul_exp_sum => mul_exp_sum_to_stg3,
      mul_sign_out => mul_sign_out_to_stg3,
      mul_a_is_nan => mul_a_is_nan_to_stg3,
      mul_b_is_nan => mul_b_is_nan_to_stg3,
      mul_a_is_inf => mul_a_is_inf_to_stg3,
      mul_b_is_inf => mul_b_is_inf_to_stg3,
      mul_a_is_zero => mul_a_is_zero_to_stg3,
      mul_b_is_zero => mul_b_is_zero_to_stg3,
      mul_out_rm => mul_out_rm_to_stg3,
      
      div_quotient => div_quotient_to_stg3,
      div_sticky => div_sticky_to_stg3,
      div_out_exp => div_out_exp_to_stg3,
      div_out_sign => div_out_sign_to_stg3,
      div_out_special => div_out_special_to_stg3,
      div_out_special_result => div_out_special_result_to_stg3,
      div_out_valid => div_out_valid_to_stg3,
      div_busy => div_busy_to_stg3,
      div_rm_out => div_out_rm_to_stg3,
      ------div_s1_valid_out => div_valid_to_stg2_out_stg1,
      
     
      -- Instruction address:
      pc_out => pc_to_stg3,

      -- CSR signals:
      csr_addr_out => csr_addr_to_stg3,
      csr_write_out => csr_write_to_stg3,
      csr_value_out => csr_value_to_stg3,

      alu_op_out => alu_op_to_stg3,

      -- Control signals:
      rd_write_out => rd_write_to_stg3,
      frd_write_out => frd_write_to_stg3,  ---- fpu.sv    out from stage 2

      branch_out => branch_to_stg3,

      -- Memory control signals:
      mem_op_out => mem_op_to_stg3,
      mem_size_out => mem_size_to_stg3,

      -- Whether the instruction should be counted:
      count_instruction_out => count_instruction_to_stg3,

      -- Exception control registers:
      mtvec_out => mtvec_to_stg3,

      -- Exception outputs:
      exception_out => exception_to_stg3,
      exception_context_out => exception_context_to_stg3

    );

  exe_stg3_instance : entity work.fp_exe_stg3
    port map(
      clk => clk,
      reset => reset,
      stall => stall_exe_stg2 ,
      start => div_start,  ---- fpu.sv div start signal
      internal_stall => internal_stall,


      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,

      -- Data memory outputs:
      dmem_address_in => dmem_address_to_stg3,
      dmem_data_in => dmem_data_to_stg3,
      dmem_data_size_in => dmem_data_size_to_stg3,
      dmem_read_req_in => dmem_read_req_to_stg3,
      dmem_write_req_in => dmem_write_req_to_stg3,

      -- Register addresses:
      rd_addr_in => rd_addr_to_stg3,
      frd_addr_in => frd_addr_to_stg3,   ----fpu.sv

      -- Register values:
      bw_rd_data_in => bw_alu_result_to_stg3,
      add_valid_in => add_valid_out_s2,
      add_s1_valid_out => add_valid_out_s1,  

      
      -- FPU Stage 2 all 4 operations inputs (for final muxing)
      add_sign_in => add_out_sign_to_stg3,
      add_exp_in => add_out_exp_to_stg3,
      add_mant_in => add_out_mant_to_stg3,
      add_rm_in => add_out_rm_to_stg3,
      
      sub_sign_in => sub_out_sign_to_stg3,
      sub_exp_in => sub_out_exp_to_stg3,
      sub_mant_in => sub_out_mant_to_stg3,
      sub_rm_in => sub_out_rm_to_stg3,
      
      mul_product_in => mul_product_to_stg3,
      mul_exp_sum_in => mul_exp_sum_to_stg3,
      mul_sign_in => mul_sign_out_to_stg3,
      mul_a_is_nan => mul_a_is_nan_to_stg3,
      mul_b_is_nan => mul_b_is_nan_to_stg3,
      mul_a_is_inf => mul_a_is_inf_to_stg3,
      mul_b_is_inf => mul_b_is_inf_to_stg3,
      mul_a_is_zero => mul_a_is_zero_to_stg3,
      mul_b_is_zero => mul_b_is_zero_to_stg3,
      mul_rm_in => mul_out_rm_to_stg3,
      
      div_quotient_in => div_quotient_to_stg3,
      div_sticky_in => div_sticky_to_stg3,
      div_exp_in => div_out_exp_to_stg3,
      div_sign_in => div_out_sign_to_stg3,
      div_special_in => div_out_special_to_stg3,
      div_special_result_in => div_out_special_result_to_stg3,
      div_valid_in => div_out_valid_to_stg3,
      
      instruction_in => instruction_in,  -- For funct7

      Pst_result_in => Pst_result_to_stg3,
      Ngt_result_in => Ngt_result_to_stg3,

      W1_in => W1_to_stg3,
      W2_in => W2_to_stg3,
      W3_in => W3_to_stg3,
      W4_in => W4_to_stg3,
      Lpp_in => Lpp_to_stg3,

      -- Instruction address:
      pc_in => pc_to_stg3,

      -- CSR signals:
      csr_addr_in => csr_addr_to_stg3,
      csr_write_in => csr_write_to_stg3,
      csr_value_in => csr_value_to_stg3,

      -- csd alu inputs
      alu_op_in => alu_op_to_stg3,

      -- Control signals:
      rd_write_in => rd_write_to_stg3,
      frd_write_in => frd_write_to_stg3,  ---- fpu.sv  ----write in  out from stg2

      branch_in => branch_to_stg3,

     

      -- Memory control signals:
      mem_op_in => mem_op_to_stg3,
      mem_size_in => mem_size_to_stg3,

      -- Whether the instruction should be counted:
      count_instruction_in => count_instruction_to_stg3,

      -- Exception control registers:
      mtvec_in => mtvec_to_stg3,

      -- Exception outputs:
      exception_in => exception_to_stg3,
      exception_context_in => exception_context_to_stg3,

      -- Data memory outputs:
      dmem_address_out => dmem_address,
      dmem_data_out => dmem_data_out,
      dmem_data_size_out => dmem_data_size,
      dmem_read_req_out => dmem_read_req,
      dmem_write_req_out => dmem_write_req,

      -- Register addresses:
      rd_addr_out => rd_addr_to_forwarding_stg3,
      frd_addr_out => frd_addr_to_forwarding_stg3,   -----output of execute stage destination register
     

      -- Register values:
      rd_data_out => rd_data_out,
    
      frd_data_out => frd_data_stg3,
      bw_rd_data_out => bw_to_forwarding_stg3,
      

      --csd_rd_data_out => csd_to_forwarding_stg3,

      -- Instruction address:
      pc_out => pc_out,

      -- CSR signals:
      csr_addr_out => csr_addr_out,
      csr_write_out => csr_write_to_hazard_stg3,
      csr_value_out => csr_value_out,

      alu_op_out => alu_op_to_forwarding_stg3,

      -- Control signals:
      rd_write_out => rd_write_to_forwarding_stg3,
      frd_write_out => frd_write_to_forwarding_stg3,  ---- fpu.sv   out from stage 3
      branch_out => branch_out,

      -- Memory control signals:
      mem_op_out => mem_op_to_hazard_stg3,
      mem_size_out => mem_size_out,

      -- Whether the instruction should be counted:
      count_instruction_out => count_instruction_out,

      -- Exception control registers:
      mtvec_out => mtvec_out,
      div_rm_in => div_out_rm_to_stg3,

      div_s1_valid_out => div_valid_to_stg2,

      -- Exception outputs:
      exception_out => exception_to_hazard_stg3,
      exception_context_out => exception_context_out_mem,
      
      -- DIV done signal for stall control in pp_core
      div_busy => div_busy_to_stg3,
      
      s3_busy       => div_busy_out,
      div_done_out => div_done

    );

    ------forward process is right i guess------
 alu_x_forward : process (
     -- stall_exe_stg1, rs1_forwarded_reg,
    alu_op_to_stg3, alu_op_to_forwarding_stg3,
    rd_write_to_stg3, rd_addr_to_stg3,
    rs1_addr, bw_alu_result_to_stg3,
    rd_write_to_forwarding_stg3, rd_addr_to_forwarding_stg3, bw_to_forwarding_stg3,
    mem_rd_write, mem_rd_addr, mem_rd_value,
    wb_rd_write, wb_rd_addr, wb_rd_value,
    rs1_data
    )
  begin
     -- if (stall_exe_stg1 ='0') then
        if rd_write_to_stg3 = '1' and rd_addr_to_stg3 = rs1_addr and rd_addr_to_stg3 /= b"00000" and (not is_csd_op(alu_op_to_stg3)) then
          rs1_forwarded <= bw_alu_result_to_stg3;
        elsif rd_write_to_forwarding_stg3 = '1' and rd_addr_to_forwarding_stg3 = rs1_addr and rd_addr_to_forwarding_stg3 /= b"00000" and (not is_csd_op(alu_op_to_forwarding_stg3)) then
          rs1_forwarded <= bw_to_forwarding_stg3;
        elsif mem_rd_write = '1' and mem_rd_addr = rs1_addr and mem_rd_addr /= b"00000" then
          rs1_forwarded <= mem_rd_value;
        elsif wb_rd_write = '1' and wb_rd_addr = rs1_addr and wb_rd_addr /= b"00000" then
          rs1_forwarded <= wb_rd_value;
        else
          rs1_forwarded <= rs1_data;
        end if;
--    else
--        rs1_forwarded <= rs1_forwarded_reg;
--    end if;
  end process alu_x_forward;

fp_alu_x_forward : process (
    alu_op_to_stg3, alu_op_to_forwarding_stg3,
    frd_write_to_stg3, frd_addr_to_stg3,
    frs1_addr,
    frd_write_to_forwarding_stg3, frd_addr_to_forwarding_stg3,
    frd_data_stg3,
    mem_frd_write, mem_frd_addr, mem_frd_value,
    wb_frd_write, wb_frd_addr, wb_frd_value,
    frs1_data
    )
  begin
    
     --if frd_write_to_stg3 = '1' and frd_addr_to_stg3 = frs1_addr  then
     --   frs1_forwarded <= frs1_data;  -- FPU result from current Stage 3
      if frd_write_to_forwarding_stg3 = '1' and frd_addr_to_forwarding_stg3 = frs1_addr  then
        frs1_forwarded <= frd_data_stg3;  -- Also from Stage 3 output
      elsif mem_frd_write = '1' and mem_frd_addr = frs1_addr  then
        frs1_forwarded <= mem_frd_value;  -- MEM stage
      elsif wb_frd_write = '1' and wb_frd_addr = frs1_addr  then
        frs1_forwarded <= wb_frd_value;  -- WB stage
      else
        frs1_forwarded <= frs1_data;
end if;

  end process fp_alu_x_forward;


   alu_y_forward : process (
   -- stall_exe_stg1, rs2_forwarded_reg,
   alu_op_to_stg3, alu_op_to_forwarding_stg3,
   rd_write_to_stg3, rd_addr_to_stg3, rs2_addr, 
   bw_alu_result_to_stg3, rd_write_to_forwarding_stg3, 
   rd_addr_to_forwarding_stg3, bw_to_forwarding_stg3, 
   mem_rd_write, mem_rd_addr, mem_rd_value, wb_rd_write, 
   wb_rd_addr, wb_rd_value, rs2_data)
 begin
     -- if (stall_exe_stg1 ='0') then
        if rd_write_to_stg3 = '1' and rd_addr_to_stg3 = rs2_addr and rd_addr_to_stg3 /= b"00000" and (not is_csd_op(alu_op_to_stg3))then
          rs2_forwarded <= bw_alu_result_to_stg3;
        elsif rd_write_to_forwarding_stg3 = '1' and rd_addr_to_forwarding_stg3 = rs2_addr and rd_addr_to_forwarding_stg3 /= b"00000" and (not is_csd_op(alu_op_to_forwarding_stg3)) then
          rs2_forwarded <= bw_to_forwarding_stg3;
        elsif mem_rd_write = '1' and mem_rd_addr = rs2_addr and mem_rd_addr /= b"00000" then
          rs2_forwarded <= mem_rd_value;
        elsif wb_rd_write = '1' and wb_rd_addr = rs2_addr and wb_rd_addr /= b"00000" then
          rs2_forwarded <= wb_rd_value;
        else
          rs2_forwarded <= rs2_data;
        end if;
--    else                           
--        rs2_forwarded <= rs2_forwarded_reg;
--    end if;                        
 end process alu_y_forward;

  fp_alu_y_forward : process (
   alu_op_to_stg3, alu_op_to_forwarding_stg3,
   frd_write_to_stg3, frd_addr_to_stg3, frs2_addr, 
   frd_write_to_forwarding_stg3, 
   frd_addr_to_forwarding_stg3, 
   frd_data_stg3,
   mem_frd_write, mem_frd_addr, mem_frd_value, wb_frd_write, 
   wb_frd_addr, wb_frd_value, frs2_data)
 begin
     -- if (stall_exe_stg1 ='0') then
        --if frd_write_to_stg3 = '1' and frd_addr_to_stg3 = frs2_addr   then
        --  frs2_forwarded <= frs2_data;  --- i think its correct now but still needs to check
        if frd_write_to_forwarding_stg3 = '1' and frd_addr_to_forwarding_stg3 = frs2_addr  then
          frs2_forwarded <= frd_data_stg3;
        elsif mem_frd_write = '1' and mem_frd_addr = frs2_addr  then
          frs2_forwarded <= mem_frd_value;
        elsif wb_frd_write = '1' and wb_frd_addr = frs2_addr  then
          frs2_forwarded <= wb_frd_value;
        else
          frs2_forwarded <= frs2_data;
        end if;
                       
 end process fp_alu_y_forward;

   -------------------------------need to verify for fpus
  detect_load_hazard : process (
    mem_op_to_hazard_stg3, rd_addr_to_forwarding_stg3,frd_addr_to_forwarding_stg3 ,
    mem_op_to_stg3, rd_addr_to_stg3, frd_addr_to_stg3, mem_mem_op, mem_rd_addr, mem_frd_addr,
    rs1_addr,frs1_addr, rs2_addr, frs2_addr, alu_x_src, alu_y_src)
  begin

    load_hazard_detected <= '0';

    ---or mem_op_to_stg3 = MEMOP_TYPE_LOAD_FP and (frd_addr_to_stg3 = frs1_addr)  or ( frd_addr_to_stg3 = frs2_addr ))
    
    if (mem_op_to_stg3 = MEMOP_TYPE_LOAD  or mem_op_to_stg3 = MEMOP_TYPE_LOAD_UNSIGNED) and
      ((alu_x_src = ALU_SRC_REG and rd_addr_to_stg3 = rs1_addr and rs1_addr /= b"00000" )  or
      (alu_y_src = ALU_SRC_REG and rd_addr_to_stg3 = rs2_addr and rs2_addr /= b"00000"))  then

      load_hazard_detected <= '1';

    elsif (mem_op_to_stg3 = MEMOP_TYPE_LOAD_FP) and 
    ((alu_x_src = ALU_SRC_REG and frd_addr_to_stg3 = frs1_addr)  or 
    ( alu_y_src = ALU_SRC_REG and frd_addr_to_stg3 = frs2_addr )) then
      load_hazard_detected <= '1';

    elsif (mem_op_to_hazard_stg3 = MEMOP_TYPE_LOAD or mem_op_to_hazard_stg3 = MEMOP_TYPE_LOAD_UNSIGNED) and
      ((alu_x_src = ALU_SRC_REG and rd_addr_to_forwarding_stg3 = rs1_addr and rs1_addr /= b"00000")  or 
      (alu_y_src = ALU_SRC_REG and rd_addr_to_forwarding_stg3 = rs2_addr and rs2_addr /= b"00000"))  then

      load_hazard_detected <= '1';

    elsif  (mem_op_to_hazard_stg3 = MEMOP_TYPE_LOAD_FP) and 
    ((alu_x_src = ALU_SRC_REG and frd_addr_to_forwarding_stg3 = frs1_addr ) or 
    (alu_y_src = ALU_SRC_REG and frd_addr_to_forwarding_stg3 = frs2_addr )) then

      load_hazard_detected <= '1';
      ---or mem_mem_op = MEMOP_TYPE_LOAD_FP
    elsif (mem_mem_op = MEMOP_TYPE_LOAD 
     or mem_mem_op = MEMOP_TYPE_LOAD_UNSIGNED) and
      ((alu_x_src = ALU_SRC_REG and mem_rd_addr = rs1_addr and rs1_addr /= b"00000" )  or 
      (alu_y_src = ALU_SRC_REG and mem_rd_addr = rs2_addr and rs2_addr /= b"00000") ) then

      load_hazard_detected <= '1';
    elsif (mem_mem_op = MEMOP_TYPE_LOAD_FP ) and
    ((alu_x_src = ALU_SRC_REG and  mem_frd_addr = frs1_addr ) or
    (alu_y_src = ALU_SRC_REG and mem_frd_addr = frs2_addr )) then

      load_hazard_detected <= '1';

     


    end if;
  end process detect_load_hazard;

  detect_csr_hazard : process (
    csr_write_to_stg3, csr_write_to_hazard_stg3, 
    mem_csr_write, wb_csr_write, exception_to_stg3, 
    exception_to_hazard_stg3, mem_exception, wb_exception)
  begin

    csr_hazard_detected <= '0';

    if csr_write_to_stg3 /= CSR_WRITE_NONE or csr_write_to_hazard_stg3 /= CSR_WRITE_NONE or mem_csr_write /= CSR_WRITE_NONE or 
    wb_csr_write /= CSR_WRITE_NONE or exception_to_stg3 = '1' or exception_to_hazard_stg3 ='1' or mem_exception = '1' or wb_exception = '1' then
      csr_hazard_detected <= '1';  
    end if;
  end process detect_csr_hazard;

    -- potential data hazard (RAW) due to CSD Arithme operations ->IE1/->IE3
--  detect_csd_instr_hazard : process (alu_op_to_forwarding_stg3, rd_write_to_forwarding_stg3, rd_addr_to_forwarding_stg3, rs1_addr, rs2_addr)
--    variable csd_hazard : std_logic := '0';
--  begin

--    csd_hazard := '0';
--    if (rd_write_to_forwarding_stg3 = '1' and (rd_addr_to_forwarding_stg3 = rs1_addr or rd_addr_to_forwarding_stg3 = rs2_addr) 
--    and rd_addr_to_forwarding_stg3 /= b"00000" and is_csd_op(alu_op_to_forwarding_stg3)) then

--      csd_hazard := '1';

--    end if;

--    csd_instruction_hazard <= csd_hazard;

--  end process detect_csd_instr_hazard;
  
  hazard_detected <= load_hazard_detected or csr_hazard_detected ;--or (csd_instruction_hazard);

end architecture behaviour;