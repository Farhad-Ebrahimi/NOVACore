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

entity fp_exe_stg2 is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;
    

    -- Data memory outputs:
    x_sign_in : in std_logic_vector(32 downto 0);
    x_data_in : in std_logic_vector(32 downto 0);
    y_sign_in : in std_logic_vector(32 downto 0);
    y_data_in : in std_logic_vector(32 downto 0);

    -- Data memory outputs:
    dmem_address_in   : in std_logic_vector(31 downto 0);
    dmem_data_in      : in std_logic_vector(31 downto 0);
    ----- dmem_fpdata_in      : in std_logic_vector(31 downto 0);
    dmem_data_size_in : in std_logic_vector(1 downto 0);
    dmem_read_req_in  : in std_logic;
    dmem_write_req_in : in std_logic;

    -- Register addresses:
    rd_addr_in : in register_address;
    frd_addr_in : in register_address;    ----fpu.sv

    -- Register values:
    rd_data_in : in std_logic_vector(31 downto 0);
    --frd_data_in : in std_logic_vector(31 downto 0);   ----fpu.sv

    -- Instruction address:
    pc_in : in std_logic_vector(31 downto 0);
 
    -- ADD Stage 1 outputs
    add_A_sign_in : in std_logic;   ----from stg 1
    add_B_sign_in : in std_logic;
    add_A_exp_in : in std_logic_vector(7 downto 0);
    add_B_exp_in : in std_logic_vector(7 downto 0);
    add_A_mant_in : in std_logic_vector(26 downto 0);
    add_B_mant_in : in std_logic_vector(26 downto 0);
    add_rm_in : in std_logic_vector(2 downto 0);
    
    -- SUB Stage 1 outputs
    sub_A_sign_in : in std_logic;
    sub_B_sign_in : in std_logic;
    sub_A_exp_in : in std_logic_vector(7 downto 0);
    sub_B_exp_in : in std_logic_vector(7 downto 0);
    sub_A_mant_in : in std_logic_vector(26 downto 0);
    sub_B_mant_in : in std_logic_vector(26 downto 0);
    sub_rm_in : in std_logic_vector(2 downto 0);
    
    -- MUL Stage 1 outputs (including fractions)
    mul_A_sign_in : in std_logic;
    mul_B_sign_in : in std_logic;
    mul_A_exp_in : in std_logic_vector(7 downto 0);
    mul_B_exp_in : in std_logic_vector(7 downto 0);
    mul_A_frac_in : in std_logic_vector(22 downto 0);  -- Raw fraction for NaN/Inf detection
    mul_B_frac_in : in std_logic_vector(22 downto 0);
    mul_A_mant_in : in std_logic_vector(26 downto 0);
    mul_B_mant_in : in std_logic_vector(26 downto 0);
    mul_rm_in : in std_logic_vector(2 downto 0);
    
    -- DIV Stage 1 outputs
    div_x_val_in : in std_logic_vector(31 downto 0);
    div_y_val_in : in std_logic_vector(31 downto 0);
    div_exp_in : in std_logic_vector(7 downto 0);
    div_sign_in : in std_logic;
    div_special_in : in std_logic;
    div_special_result_in : in std_logic_vector(31 downto 0);
    div_valid_in : in std_logic;

    -- CSR signals:
    csr_addr_in  : in csr_address;
    csr_write_in : in csr_write_mode;
    csr_value_in : in std_logic_vector(31 downto 0);

    -- csd alu inputs
    alu_op_in  : in alu_operation; -------coming from execution stg1
    alu_op_out : out alu_operation;
    alu_y_in  : in std_logic_vector(31 downto 0);

    -- Control signals:
    rd_write_in : in std_logic;
    frd_write_in : in std_logic;  ---- fpu.sv
    branch_in   : in branch_type;

    -- Memory control signals:
    mem_op_in   : in memory_operation_type;
    mem_size_in : in memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_in : in std_logic;

    instruction_in : in std_logic_vector(31 downto 0);  ----fpu 2026

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
    Pst_result  : out std_logic_vector(31 downto 0);
    Ngt_result  : out std_logic_vector(31 downto 0);
    
    W1_out  : out std_logic_vector(83 downto 0);
    W2_out  : out std_logic_vector(83 downto 0);
    W3_out  : out std_logic_vector(83 downto 0);
    W4_out  : out std_logic_vector(83 downto 0);
    Lpp_out  : out std_logic_vector(67 downto 0);
    
    rd_data_out : out std_logic_vector(31 downto 0);
    --frd_data_out : out std_logic_vector(31 downto 0);   ----fpu.sv

    -- FPU Stage 2 output signals (all 4 operations for downstream muxing)
    -- ADD Stage 2 outputs
    add_out_sign : out std_logic;
    add_out_exp : out std_logic_vector(7 downto 0);
    add_out_mant : out std_logic_vector(27 downto 0);
    add_out_rm : out std_logic_vector(2 downto 0);
    add_out_valid : out std_logic;

    add_valid_in : in std_logic;
    internal_stall : in STD_LOGIC;
    
    -- SUB Stage 2 outputs
    sub_out_sign : out std_logic;
    sub_out_exp : out std_logic_vector(7 downto 0);
    sub_out_mant : out std_logic_vector(27 downto 0);
    sub_out_rm : out std_logic_vector(2 downto 0);
    
    -- MUL Stage 2 outputs
    mul_product : out std_logic_vector(47 downto 0);
    mul_exp_sum : out std_logic_vector(7 downto 0);
    mul_sign_out : out std_logic;
    mul_a_is_nan : out std_logic;
    mul_b_is_nan : out std_logic;
    mul_a_is_inf : out std_logic;
    mul_b_is_inf : out std_logic;
    mul_a_is_zero : out std_logic;
    mul_b_is_zero : out std_logic;
    mul_out_rm : out std_logic_vector(2 downto 0);
    
    -- DIV Stage 2 outputs
    div_quotient : out std_logic_vector(31 downto 0);
    div_sticky : out std_logic;
    div_out_exp : out std_logic_vector(7 downto 0);
    div_out_sign : out std_logic;
    div_out_special : out std_logic;
    div_out_special_result : out std_logic_vector(31 downto 0);
    div_out_valid : out std_logic;
    div_busy : out std_logic;
    div_rm_in : in std_logic_vector(2 downto 0);
    div_rm_out : out std_logic_vector(2 downto 0);
    ----div_s1_valid_in : out std_logic;

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
    exception_context_out : out csr_exception_context
  );
end entity fp_exe_stg2;

architecture behaviour of fp_exe_stg2 is
  signal alu_op : alu_operation;

  signal alu_y, alu_result, bw_alu_result, csd_alu_result : std_logic_vector(31 downto 0);

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
  ---signal dmem_fpdata      : std_logic_vector(31 downto 0);
  signal dmem_data_size : std_logic_vector(1 downto 0);
  signal dmem_write_req     : std_logic;
  signal dmem_read_req      : std_logic;
  

  signal x_sign : std_logic_vector(32 downto 0);
  signal x_data : std_logic_vector(32 downto 0);
  signal y_sign : std_logic_vector(32 downto 0);
  signal y_data : std_logic_vector(32 downto 0);

  signal funct7_in :std_logic_vector(6 downto 0); --- FPU funct7

  -- signal Pst_result     : std_logic_vector(31 downto 0);
  -- signal Ngt_result     : std_logic_vector(31 downto 0);


  ---signal div_s1_valid_in : std_logic;  ----from stage1 to stage2;

 
  
begin

  -- Register values should not be latched in by a clocked process,
  -- this is already done in the register files.
  csr_value_out<=csr_value;
  rd_data_out <= bw_alu_result;

  funct7_in <= instruction_in(31 downto 25); --- FPU funct7

  branch_out <= branch;
  alu_op_out <= alu_op;

  mem_op_out   <= mem_op;
  mem_size_out <= mem_size;

  csr_write_out <= csr_write;
  csr_addr_out  <= csr_addr;

  pc_out <= pc;
  exception_out         <= exception;
  exception_context_out <= exception_context;

  mtvec_out <= std_logic_vector(unsigned(mtvec));

  dmem_address_out   <=  dmem_address;
  dmem_data_out      <= dmem_data;
  --dmem_fpdata_out      <= dmem_fpdata;
  dmem_data_size_out <= dmem_data_size;
  dmem_write_req_out <= dmem_write_req;
  dmem_read_req_out  <= dmem_read_req;


  -----div_s1_valid_in <= div_valid_in;  ----from stage1 to stage2;
  
  
  


  pipeline_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rd_write_out          <= '0';
        branch                <= BRANCH_NONE;
        csr_write             <= CSR_WRITE_NONE;
        mem_op                <= MEMOP_TYPE_NONE;
        count_instruction_out <= '0';
        exception<= '0';
      elsif stall = '0' or internal_stall = '0' then
      
        pc                    <= pc_in;
        count_instruction_out <= count_instruction_in;
        
        -- Register signals:
        rd_write_out  <= rd_write_in;
        rd_addr_out   <= rd_addr_in;
        frd_write_out <= frd_write_in;  ---- for FPU
        frd_addr_out <= frd_addr_in;   ---- for FPU
        
        bw_alu_result <= rd_data_in;
        
        -- CSD ALU signals:
        alu_op   <= alu_op_in;
                
        -- CSD ALU inputs:
        x_sign <= x_sign_in;
        x_data <= x_data_in;
        y_sign <= y_sign_in;
        y_data <= y_data_in;
        alu_y   <= alu_y_in;
        
        
        

        
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
        --- dmem_fpdata      <= dmem_fpdata_in;   ---- fpu
        dmem_data_size <= dmem_data_size_in;
        dmem_write_req <= dmem_write_req_in;
        dmem_read_req  <= dmem_read_req_in;

      end if;
    end if;
  end process pipeline_register;
  

  csd_alu_instance : entity work.csd_alu
    port map(
      --y         => alu_y,
      xs        => x_sign(32 downto 0),
      xd        => x_data(32 downto 0),
      ys        => y_sign(32 downto 0),
      yd        => y_data(32 downto 0),
      P_result  => Pst_result,
      N_result  => Ngt_result,
      W1 => W1_out,
      W2 => W2_out,
      W3 => W3_out,
      W4 => W4_out,
      Lpp=>Lpp_out,
      operation => alu_op
    );

  -- FPU Stage 2 instantiation
  fpu_stg2_instance : entity work.fpu_stage2
    port map(
      clk => clk,
      reset => reset,
      stall => internal_stall,
      ----alu_op_in => alu_op,

      
      en_fadd => en_fadd,
      en_fsub => en_fsub,
      en_fmul => en_fmul,
      en_fdiv => en_fdiv,
      
      -- CSD ALU result inputs never used
      use_csd_result => '0',
      csd_result_sign => '0',
      csd_result_exp => (others => '0'),
      csd_result_mant => (others => '0'),
      
      -- ADD Stage 1 inputs  inputs from stage 1
      add_A_sign => add_A_sign_in,
      add_B_sign => add_B_sign_in,
      add_A_exp => add_A_exp_in,
      add_B_exp => add_B_exp_in,
      add_A_mant => add_A_mant_in,
      add_B_mant => add_B_mant_in,
      add_rm => add_rm_in,
      add_valid => add_valid_in,  ---need to declare add_valid_in
      
      -- ADD Stage 2 outputs to stage 3
      add_out_sign => add_out_sign,
      add_out_exp => add_out_exp,
      add_out_mant => add_out_mant,
      add_rm_out => add_out_rm,
      add_valid_out => add_out_valid , ---need to declare
      
      -- SUB Stage 1 inputs
      sub_A_sign => sub_A_sign_in,
      sub_B_sign => sub_B_sign_in,
      sub_A_exp => sub_A_exp_in,
      sub_B_exp => sub_B_exp_in,
      sub_A_mant => sub_A_mant_in,
      sub_B_mant => sub_B_mant_in,
      sub_rm => sub_rm_in,
      
      -- SUB Stage 2 outputs
      sub_out_sign => sub_out_sign,
      sub_out_exp => sub_out_exp,
      sub_out_mant => sub_out_mant,
      sub_rm_out => sub_out_rm,
      
      -- MUL Stage 1 inputs
      mul_A_sign => mul_A_sign_in,
      mul_B_sign => mul_B_sign_in,
      mul_A_exp => mul_A_exp_in,
      mul_B_exp => mul_B_exp_in,
      mul_A_frac => mul_A_frac_in,
      mul_B_frac => mul_B_frac_in,
      mul_A_mant => mul_A_mant_in,
      mul_B_mant => mul_B_mant_in,
      mul_rm => mul_rm_in,
      
      -- MUL Stage 2 outputs to stage 3
      mul_product => mul_product,
      mul_exp_sum => mul_exp_sum,
      mul_sign_out => mul_sign_out,
      mul_a_is_nan => mul_a_is_nan,
      mul_b_is_nan => mul_b_is_nan,
      mul_a_is_inf => mul_a_is_inf,
      mul_b_is_inf => mul_b_is_inf,
      mul_a_is_zero => mul_a_is_zero,
      mul_b_is_zero => mul_b_is_zero,
      mul_rm_out => mul_out_rm,
      
      -- DIV Stage 1 inputs
      div_x_val => div_x_val_in,
      div_y_val => div_y_val_in,
      div_exp => div_exp_in,
      div_sign => div_sign_in,
      div_special => div_special_in,
      div_special_result => div_special_result_in,
      div_valid => div_valid_in,    ----from s1 to s2
      div_rm_in           => div_rm_in,
      
      -- DIV Stage 2 outputs
      div_quotient => div_quotient,
      div_sticky => div_sticky,
      div_exp_out => div_out_exp,
      div_sign_out => div_out_sign,
      div_special_out => div_out_special,
      div_special_result_out => div_out_special_result,
      -----div_s1_valid_out  => div_s1_valid_in,     ---- still need to check 
      div_valid_out => div_out_valid,
      div_rm_out          => div_rm_out,
      div_busy => div_busy
    );
    
end architecture behaviour;