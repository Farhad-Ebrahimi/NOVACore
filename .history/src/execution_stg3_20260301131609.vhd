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

entity fp_exe_stg3 is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;
    start : in  std_logic;
    internal_stall : in STD_LOGIC;

    -- Data memory outputs:
    dmem_address_in   : in std_logic_vector(31 downto 0);
    dmem_data_in      : in std_logic_vector(31 downto 0);
    ---dmem_fpdata_in      : in std_logic_vector(31 downto 0);
    dmem_data_size_in : in std_logic_vector(1 downto 0);
    dmem_read_req_in  : in std_logic;
    dmem_write_req_in : in std_logic;

    -- Register addresses:
    rd_addr_in : in register_address;
    frd_addr_in : in register_address;   ----fpu.sv

    -- Register values:
    Pst_result_in : in std_logic_vector(31 downto 0);
    Ngt_result_in : in std_logic_vector(31 downto 0);
    
    W1_in  : in std_logic_vector(83 downto 0);
    W2_in  : in std_logic_vector(83 downto 0);
    W3_in  : in std_logic_vector(83 downto 0);
    W4_in  : in std_logic_vector(83 downto 0);
    Lpp_in : in std_logic_vector(67 downto 0);
    
    bw_rd_data_in    : in std_logic_vector(31 downto 0);
    

    
    
    -- FPU Stage 2 all 4 operations inputs (for final muxing by funct7)
    -- ADD Stage 2 inputs
    add_sign_in : in std_logic;
    add_exp_in : in std_logic_vector(7 downto 0);
    add_mant_in : in std_logic_vector(27 downto 0);
    add_rm_in : in std_logic_vector(2 downto 0);
    add_valid_in : in std_logic;
    add_s1_valid_out : in  std_logic;  ---- coming from stage2
    -- SUB Stage 2 inputs
    sub_sign_in : in std_logic;
    sub_exp_in : in std_logic_vector(7 downto 0);
    sub_mant_in : in std_logic_vector(27 downto 0);
    sub_rm_in : in std_logic_vector(2 downto 0);
    
    -- MUL Stage 2 inputs
    mul_product_in : in std_logic_vector(47 downto 0);
    mul_exp_sum_in : in std_logic_vector(7 downto 0);
    mul_sign_in : in std_logic;
    mul_a_is_nan : in std_logic;
    mul_b_is_nan : in std_logic;
    mul_a_is_inf : in std_logic;
    mul_b_is_inf : in std_logic;
    mul_a_is_zero : in std_logic;
    mul_b_is_zero : in std_logic;
    mul_rm_in : in std_logic_vector(2 downto 0);
    
    -- DIV Stage 2 inputs
    div_quotient_in : in std_logic_vector(31 downto 0);
    div_sticky_in : in std_logic;
    div_exp_in : in std_logic_vector(7 downto 0);
    div_sign_in : in std_logic;
    div_special_in : in std_logic;
    div_special_result_in : in std_logic_vector(31 downto 0);
    div_valid_in : in std_logic;
    div_rm_in : in std_logic_vector(2 downto 0);
    div_s1_valid_out : in  std_logic;  ---- coming from stage2
    div_busy        : in  std_logic;
    
    instruction_in : in std_logic_vector(31 downto 0);  -- For funct7

    -- Instruction address:
    pc_in : in std_logic_vector(31 downto 0);

    -- CSR signals:
    csr_addr_in  : in csr_address;
    csr_write_in : in csr_write_mode;
    csr_value_in : in std_logic_vector(31 downto 0);

    -- csd alu inputs
    alu_op_in  : in alu_operation;
    alu_op_out : out alu_operation;

    -- Control signals:
    rd_write_in : in std_logic;
    frd_write_in : in std_logic;  ---- fpu.sv
    branch_in   : in branch_type;

    -- Memory control signals:
    mem_op_in   : in memory_operation_type;
    mem_size_in : in memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_in : in std_logic;

    -- Exception control registers:
    mtvec_in : in std_logic_vector(31 downto 0);

    -- Exception outputs:
    exception_in         : in std_logic;
    exception_context_in : in csr_exception_context;

    -- Data memory outputs:
    dmem_address_out   : out std_logic_vector(31 downto 0);
    dmem_data_out      : out std_logic_vector(31 downto 0);
    ---dmem_fpdata_out      : out std_logic_vector(31 downto 0);
    dmem_data_size_out : out std_logic_vector(1 downto 0);
    dmem_read_req_out  : out std_logic;
    dmem_write_req_out : out std_logic;

    -- Register addresses:
    rd_addr_out : out register_address;
    frd_addr_out : out register_address;   ----fpu.sv

    -- Register values:
    rd_data_out : out std_logic_vector(31 downto 0);
    frd_data_out : out std_logic_vector(31 downto 0);   ----fpu.sv
    bw_rd_data_out : out std_logic_vector(31 downto 0);
    ----fp_bw_rd_data_out : out std_logic_vector(31 downto 0);
    --sd_rd_data_out : out std_logic_vector(63 downto 0);
    -- Instruction address:
    pc_out : out std_logic_vector(31 downto 0);


    en_fadd : in std_logic;
    en_fsub : in std_logic;
    en_fmul : in std_logic;
    en_fdiv : in std_logic;

    -- CSR signals:
    csr_addr_out  : out csr_address;
    csr_write_out : out csr_write_mode;
    csr_value_out : out std_logic_vector(31 downto 0);

    -- Control signals:
    rd_write_out : out std_logic;
    frd_write_out : out std_logic;  ---- fpu.sv
    branch_out   : out branch_type;

    -- Memory control signals:
    mem_op_out   : out memory_operation_type;
    mem_size_out : out memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_out : out std_logic;

    -- Exception control registers:
     mtvec_out : out std_logic_vector(31 downto 0);

    -- Exception outputs:
    exception_out         : out std_logic;
    exception_context_out : out csr_exception_context;


    flags_out        : out std_logic_vector(4 downto 0);
    --fpu_result_out       : out std_logic_vector(31 downto 0);
    
    -- DIV done signal (propagate up to pp_core for stall control)
    s3_busy        : out std_logic;



    div_done_out : out std_logic
  );
end entity fp_exe_stg3;

architecture behaviour of fp_exe_stg3 is
  signal alu_op : alu_operation;

  signal alu_result, bw_alu_result : std_logic_vector(31 downto 0);
  signal csd_alu_result,csd_alu_result_AS : std_logic_vector(31 downto 0);
  signal csd_alu_result_HL: std_logic_vector(63 downto 0);
  signal mem_op   : memory_operation_type;
  signal mem_size : memory_operation_size;

  signal pc     : std_logic_vector(31 downto 0);
  signal branch : branch_type;

  signal mtvec : std_logic_vector(31 downto 0);

  signal csr_write : csr_write_mode;
  signal csr_addr  : csr_address;
  signal csr_value : std_logic_vector(31 downto 0);

  signal exception         : std_logic;
  signal exception_context : csr_exception_context;

  signal dmem_address   : std_logic_vector(31 downto 0);
  signal dmem_data      : std_logic_vector(31 downto 0);
  signal dmem_data_size : std_logic_vector(1 downto 0);
  signal dmem_write_req     : std_logic;
  signal dmem_read_req      : std_logic;



    signal add_done      : std_logic;

  signal frd_addr_latched : register_address;  ---- for FPU
  signal frd_data_latched : std_logic_vector(31 downto 0);  ---- for FPU
  signal frd_write_latched : std_logic;  ---- for FPU
  
  signal Pos_Add     : std_logic_vector(31 downto 0);
  signal Neg_Add     : std_logic_vector(31 downto 0);
  
  signal Pos_mul     : std_logic_vector(63 downto 0);
  signal Neg_mul     : std_logic_vector(63 downto 0);
  
  signal W1, W2, W3, W4 : std_logic_vector(83 downto 0);
  signal Lpp : std_logic_vector(67 downto 0);

  -- FPU Stage 3 signals
  signal fpu_result : std_logic_vector(31 downto 0);





begin

  -- Register values should not be latched in by a clocked process,
  -- this is already done in the register files.
  csr_value_out<=csr_value;
  rd_data_out <= alu_result;
  bw_rd_data_out <= bw_alu_result;

  branch_out <= branch;
  alu_op_out <= alu_op_ex when is_fp_op(alu_op_ex) else alu_op;

  mem_op_out   <= mem_op;
  mem_size_out <= mem_size;

  csr_write_out <= csr_write;
  csr_addr_out  <= csr_addr;

  pc_out <= pc;
  exception_out         <= exception;
  exception_context_out <= exception_context;

  mtvec_out <= std_logic_vector(unsigned(mtvec));

  dmem_address_out   <=  alu_result when (mem_op /= MEMOP_TYPE_NONE and mem_op /= MEMOP_TYPE_INVALID) and exception = '0'else dmem_address;
  dmem_data_out      <= dmem_data;
  
  dmem_data_size_out <= dmem_data_size;
  dmem_write_req_out <= dmem_write_req;
  dmem_read_req_out  <= dmem_read_req;

  ---frd_data_out <=  fpu_result;
  frd_data_out <= bw_alu_result when alu_op = ALU_FMVWX or (alu_op = ALU_FCVT_S_W or alu_op = ALU_FCVT_S_WU ) else fpu_result;

  -----integer to float 
  
 


  pipeline_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rd_write_out          <= '0';
        frd_write_out         <= '0';  ----feb2026
        branch                <= BRANCH_NONE;
        csr_write             <= CSR_WRITE_NONE;
        mem_op                <= MEMOP_TYPE_NONE;
        count_instruction_out <= '0';
        exception             <= '0';
        -- Initialize latched DIV done flag on reset
        
   
      elsif stall = '0' and internal_stall = '0' then   ----or internal_stall = '0'
      
        pc                    <= pc_in;
        count_instruction_out <= count_instruction_in;
        
        -- Register signals:
        rd_write_out  <= rd_write_in;
        rd_addr_out   <= rd_addr_in;
        frd_write_out <= frd_write_in;  ---- for FPU
        frd_addr_out <= frd_addr_in;   ---- for FPU
       --- frd_data_out <= frd_data_in;   ---- for FPU
        bw_alu_result <= bw_rd_data_in;
        Pos_Add    <= Pst_result_in;
        Neg_Add    <= Ngt_result_in;
        
        W1 <= W1_in;
        W2 <= W2_in;
        W3 <= W3_in;
        W4 <= W4_in;
        Lpp<= Lpp_in;
        -- CSD ALU signals:
        alu_op   <= alu_op_in;
      
        -- FPU Stage 3 latching
        ---frd_data_out <= fpu_result;   ----- not used i guess
       
        -- Control signals:
        branch   <= branch_in;
        mem_op   <= mem_op_in;
        mem_size <= mem_size_in;
        
        -- CSR signals:
        csr_write     <= csr_write_in;
        csr_addr      <= csr_addr_in;
        csr_value     <= csr_value_in;
        
        -- Exception vector base:
        mtvec <= mtvec_in;

        -- exceptio signals
        exception         <= exception_in;
        exception_context <= exception_context_in;
        
              
        -- memory stage signals
        dmem_address   <= dmem_address_in;
        dmem_data      <= dmem_data_in;
        ---dmem_fpdata      <= dmem_fpdata_in;
        dmem_data_size <= dmem_data_size_in;
        dmem_write_req <= dmem_write_req_in;
        dmem_read_req  <= dmem_read_req_in;

      else
        -- While stalled, preserve a div_done pulse so pp_core can release stall
        
      end if;
    end if;
  end process pipeline_register;
  
  mul_stg3 : entity work.mul_stg3
    port map(
      W1 => W1,
      W2 => W2,
      W3 => W3,
      W4 => W4,
      Lpp=> Lpp,
      Pos_mul=>Pos_mul,
      Neg_mul=>Neg_mul
      );
       
  csd_alu_result_AS <= std_logic_vector(unsigned(Pos_Add) + unsigned(Neg_Add) + 1);
  csd_alu_result_HL <= std_logic_vector(unsigned(Pos_mul) + unsigned(Neg_mul) + 1);
  -------- need to check,
    process (alu_op,csd_alu_result_HL,csd_alu_result_AS,bw_alu_result)
     begin
       case alu_op is
            when ALU_MUL =>
                alu_result <= csd_alu_result_HL(31 downto 0);
            when ALU_MULH | ALU_MULHU | ALU_MULHSU =>
                alu_result <= csd_alu_result_HL(63 downto 32);
            when ALU_ADD | ALU_SUB =>
                alu_result <= csd_alu_result_AS;
            when ALU_SLT | ALU_SLTU | ALU_AND | ALU_OR | ALU_XOR | ALU_SLL | ALU_SRL |ALU_SRA | ALU_FMVXW | ALU_FCVT_W | ALU_FCVT_WU =>
                alu_result <= bw_alu_result;  
             
            when others =>
                alu_result <= (others=>'0');  
        end case;
     end process;


  




  -- FPU Stage 3 instantiation
  fpu_stg3_instance : entity work.fpu_stage3
    port map(
      clk => clk,
      reset => reset,
      stall => internal_stall,
      ex_stall => stall,
      alu_op_in => alu_op,


      
      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,
      alu_op_ex => alu_op_ex,  

      funct7 => instruction_in(31 downto 25),  -- Operation selector for muxing (combinatorial from decode)
      -- ADD Stage 2 inputs
      add_sign => add_sign_in,
      add_exp => add_exp_in,
      add_mant => add_mant_in,
      add_rm => add_rm_in,
      add_valid => add_valid_in,  ---from stg2
      add_s1_valid_out => add_s1_valid_out,  ----from stg1
      
      -- SUB Stage 2 inputs
      sub_sign => sub_sign_in,
      sub_exp => sub_exp_in,
      sub_mant => sub_mant_in,
      sub_rm => sub_rm_in,
      start => start,
      
      -- MUL Stage 2 inputs
      mul_product => mul_product_in,
      mul_exp_sum => mul_exp_sum_in,
      mul_sign => mul_sign_in,
      mul_a_is_nan => mul_a_is_nan,
      mul_b_is_nan => mul_b_is_nan,
      mul_a_is_inf => mul_a_is_inf,
      mul_b_is_inf => mul_b_is_inf,
      mul_a_is_zero => mul_a_is_zero,
      mul_b_is_zero => mul_b_is_zero,
      mul_rm => mul_rm_in,

      

      
      
      -- DIV Stage 2 inputs
      div_quotient => div_quotient_in,
      div_sticky => div_sticky_in,
      div_exp => div_exp_in,
      div_sign => div_sign_in,
      div_busy => div_busy,
      div_special => div_special_in,
      div_special_result => div_special_result_in,
      div_valid => div_valid_in,
      div_rm => div_rm_in,
      div_s1_valid_out =>  div_s1_valid_out,  ----input signal
      result_out => fpu_result,   ----stored in the output of execution stg 3 that will go into mem stage. 
      flags_out => flags_out,
      s3_busy       => s3_busy,

      add_done => add_done,

      div_done => div_done_out

    );
    
  
    
end architecture behaviour;