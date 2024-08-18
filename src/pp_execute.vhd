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
  port
  (
    clk            : in std_logic;
    reset          : in std_logic;
    flush          : in std_logic;
    stall_exe_stg1 : in std_logic;
    stall_exe_stg2 : in std_logic;

    -- Interrupt inputs:
    irq                : in std_logic_vector(7 downto 0);
    software_interrupt : in std_logic;
    timer_interrupt    : in std_logic;

    -- Data memory outputs:
    dmem_address   : out std_logic_vector(31 downto 0);
    dmem_data_out  : out std_logic_vector(31 downto 0);
    dmem_data_size : out std_logic_vector(1 downto 0);
    dmem_read_req  : out std_logic;
    dmem_write_req : out std_logic;

    -- Register addresses:
    rs1_addr_in, rs2_addr_in, rd_addr_in : in register_address;
    rd_addr_out                          : out register_address;

    -- Register values:
    rs1_data_in, rs2_data_in : in std_logic_vector(31 downto 0);
    rd_data_out              : out std_logic_vector(31 downto 0);

    -- Constant values:
    shamt_in     : in std_logic_vector(4 downto 0);
    immediate_in : in std_logic_vector(31 downto 0);

    -- Instruction address:
    pc_in  : in std_logic_vector(31 downto 0);
    pc_out : out std_logic_vector(31 downto 0);

    -- Funct3 value from the instruction, used to choose which comparison
    -- is used when branching:
    funct3_in : in std_logic_vector(2 downto 0);

    -- CSR signals:
    csr_addr_in          : in csr_address;
    csr_addr_out         : out csr_address;
    csr_write_in         : in csr_write_mode;
    csr_write_out        : out csr_write_mode;
    csr_value_in         : in std_logic_vector(31 downto 0);
    csr_value_out        : out std_logic_vector(31 downto 0);
    csr_use_immediate_in : in std_logic;

    -- Control signals:
    alu_op_in    : in alu_operation;
    alu_x_src_in : in alu_operand_source;
    alu_y_src_in : in alu_operand_source;
    rd_write_in  : in std_logic;
    rd_write_out : out std_logic;
    branch_in    : in branch_type;
    branch_out   : out branch_type;

    -- Memory control signals:
    mem_op_in    : in memory_operation_type;
    mem_op_out   : out memory_operation_type;
    mem_size_in  : in memory_operation_size;
    mem_size_out : out memory_operation_size;

    -- Whether the instruction should be counted:
    count_instruction_in  : in std_logic;
    count_instruction_out : out std_logic;

    -- Exception control registers:
    ie_in, ie1_in : in std_logic;
    mie_in        : in std_logic_vector(31 downto 0);
    mtvec_in      : in std_logic_vector(31 downto 0);
    mtvec_out     : out std_logic_vector(31 downto 0);
    --mepc_in       : in  std_logic_vector(31 downto 0);

    -- Exception signals:
    decode_exception_in       : in std_logic;
    decode_exception_cause_in : in csr_exception_cause;

    -- Exception outputs:
    exception_out         : out std_logic;
    exception_context_out : out csr_exception_context;

    -- Control outputs:
    jump_out        : out std_logic;
    jump_target_out : out std_logic_vector(31 downto 0);

    -- Inputs to the forwarding logic from the MEM stage:
    mem_rd_write  : in std_logic;
    mem_rd_addr   : in register_address;
    mem_rd_value  : in std_logic_vector(31 downto 0);
    mem_csr_addr  : in csr_address;
    mem_csr_write : in csr_write_mode;
    mem_exception : in std_logic;

    -- Inputs to the forwarding logic from the WB stage:
    wb_rd_write  : in std_logic;
    wb_rd_addr   : in register_address;
    wb_rd_value  : in std_logic_vector(31 downto 0);
    wb_csr_addr  : in csr_address;
    wb_csr_write : in csr_write_mode;
    wb_exception : in std_logic;

    -- Hazard detection unit signals:
    mem_mem_op      : in memory_operation_type;
    hazard_detected : out std_logic
  );
end entity pp_execute;

architecture behaviour of pp_execute is
 
  -- signal alu_op               : alu_operation;
  signal alu_x_src, alu_y_src : alu_operand_source;

  --signal alu_x, alu_y, alu_result : std_logic_vector(31 downto 0);

  signal rs1_addr, rs2_addr, rd_addr : register_address;
  signal rs1_data, rs2_data          : std_logic_vector(31 downto 0);

  signal load_hazard_detected, csr_hazard_detected : std_logic;

  signal rs1_forwarded, rs2_forwarded : std_logic_vector(31 downto 0);

  signal csd_instruction_hazard : std_logic;

  signal mem_op_to_hazard_stg3       : memory_operation_type;
  signal rd_addr_to_forwarding_stg3  : register_address;
  signal rd_write_to_forwarding_stg3 : std_logic;
  signal bw_to_forwarding_stg3  : std_logic_vector(31 downto 0);
  signal alu_op_to_forwarding_stg3   : alu_operation;
  signal csr_write_to_hazard_stg3    : csr_write_mode;
  signal exception_to_hazard_stg3    : std_logic;

  -- output signals exe_stg1 to exe_stg2 --

  signal dmem_address_to_stg2   : std_logic_vector(31 downto 0);
  signal dmem_data_to_stg2      : std_logic_vector(31 downto 0);
  signal dmem_data_size_to_stg2 : std_logic_vector(1 downto 0);
  signal dmem_read_req_to_stg2  : std_logic;
  signal dmem_write_req_to_stg2 : std_logic;

  -- Register addresses:
  signal rd_addr_to_stg2 : register_address;

  -- Register values:
  signal rd_data_to_stg2 : std_logic_vector(31 downto 0);

  -- Instruction address:
  signal pc_to_stg2 : std_logic_vector(31 downto 0);

  -- CSR signals:
  signal csr_addr_to_stg2  : csr_address;
  signal csr_write_to_stg2 : csr_write_mode;
  signal csr_value_to_stg2 : std_logic_vector(31 downto 0);

  -- Control signals:
  signal alu_op_to_stg2   : alu_operation;
  signal rd_write_to_stg2 : std_logic;
  signal branch_to_stg2   : branch_type;

  -- Memory control signals:
  signal mem_op_to_stg2   : memory_operation_type;
  signal mem_size_to_stg2 : memory_operation_size;

  -- Whether the instruction should be counted:
  signal count_instruction_to_stg2 : std_logic;

  -- Exception control registers:
  signal mtvec_to_stg2 : std_logic_vector(31 downto 0);

  -- Exception outputs:
  signal exception_to_stg2         : std_logic;
  signal exception_context_to_stg2 : csr_exception_context;

  -- csd alu inputs
  signal x_sign_to_stg2         : std_logic_vector(32 downto 0);
  signal x_data_to_stg2         : std_logic_vector(32 downto 0);
  signal y_sign_to_stg2         : std_logic_vector(32 downto 0);
  signal y_data_to_stg2         : std_logic_vector(32 downto 0);
  signal alu_y_to_stg2          : std_logic_vector(31 downto 0);
  
    -- output signals exe_stg2 to exe_stg3 --

    signal dmem_address_to_stg3   : std_logic_vector(31 downto 0);
    signal dmem_data_to_stg3      : std_logic_vector(31 downto 0);
    signal dmem_data_size_to_stg3 : std_logic_vector(1 downto 0);
    signal dmem_read_req_to_stg3  : std_logic;
    signal dmem_write_req_to_stg3 : std_logic;
  
    -- Register addresses:
    signal rd_addr_to_stg3 : register_address;
  
    -- Register values:
    signal bw_alu_result_to_stg3: std_logic_vector(31 downto 0);
    Signal Pst_result_to_stg3 : std_logic_vector(31 downto 0);
    signal Ngt_result_to_stg3 : std_logic_vector(31 downto 0);
    
    signal W1_to_stg3 : std_logic_vector(83 downto 0);
    signal W2_to_stg3 : std_logic_vector(83 downto 0);
    signal W3_to_stg3 : std_logic_vector(83 downto 0);
    signal W4_to_stg3 : std_logic_vector(83 downto 0);
    signal Lpp_to_stg3 : std_logic_vector(67 downto 0);
  
    -- Instruction address:
    signal pc_to_stg3 : std_logic_vector(31 downto 0);
  
    -- CSR signals:
    signal csr_addr_to_stg3  : csr_address;
    signal csr_write_to_stg3 : csr_write_mode;
    signal csr_value_to_stg3 : std_logic_vector(31 downto 0);
  
    -- Control signals:
    signal alu_op_to_stg3   : alu_operation;
    signal rd_write_to_stg3 : std_logic;
    signal branch_to_stg3   : branch_type;
  
    -- Memory control signals:
    signal mem_op_to_stg3   : memory_operation_type;
    signal mem_size_to_stg3 : memory_operation_size;
  
    -- Whether the instruction should be counted:
    signal count_instruction_to_stg3 : std_logic;
  
    -- Exception control registers:
    signal mtvec_to_stg3 : std_logic_vector(31 downto 0);
  
    -- Exception outputs:
    signal exception_to_stg3         : std_logic;
    signal exception_context_to_stg3 : csr_exception_context;
  
begin

  rs1_data <= rs1_data_in;
  rs2_data <= rs2_data_in;

  mem_op_out    <= mem_op_to_hazard_stg3;
  rd_addr_out   <= rd_addr_to_forwarding_stg3;
  rd_write_out  <= rd_write_to_forwarding_stg3;
  csr_write_out <= csr_write_to_hazard_stg3;
  exception_out <= exception_to_hazard_stg3;

  update_address : process (clk)
  begin
    if rising_edge(clk) then

      if stall_exe_stg1 = '0' then
        rs1_addr  <= rs1_addr_in;
        rs2_addr  <= rs2_addr_in;
        alu_x_src <= alu_x_src_in;
        alu_y_src <= alu_y_src_in;
      end if;

      -- if stall_exe_stg2 = '0' then
        --rd_data_to_forwarding <= rd_data_to_stg2;
      -- end if;

    end if;
  end process update_address;

  exe_stg1_instance : entity work.fp_exe_stg1
    port map(
      clk   => clk,
      reset => reset,
      stall => stall_exe_stg1,
      flush => flush,

      -- Interrupt inputs:
      irq                => irq,
      software_interrupt => software_interrupt,
      timer_interrupt    => timer_interrupt,

      -- Data memory outputs:
      dmem_address   => dmem_address_to_stg2,
      dmem_data_out  => dmem_data_to_stg2,
      dmem_data_size => dmem_data_size_to_stg2,
      dmem_read_req  => dmem_read_req_to_stg2,
      dmem_write_req => dmem_write_req_to_stg2,

      rs1_forwarded => rs1_forwarded,
      rs2_forwarded => rs2_forwarded,

      x_sign_out => x_sign_to_stg2,
      x_data_out => x_data_to_stg2,
      y_sign_out => y_sign_to_stg2,
      y_data_out => y_data_to_stg2,
      alu_y_out  => alu_y_to_stg2,

      -- Register addresses:
      rd_addr_in  => rd_addr_in,
      rd_addr_out => rd_addr_to_stg2,

      -- Register values:
      rs1_addr_in => rs1_addr_in,
      rd_data_out => rd_data_to_stg2,

      -- Constant values:
      shamt_in     => shamt_in,
      immediate_in => immediate_in,

      -- Instruction address:
      pc_in  => pc_in,
      pc_out => pc_to_stg2,

      -- Funct3 value from the instruction, used to choose which comparison
      -- is used when branching:
      funct3_in => funct3_in,

      -- CSR signals:
      csr_addr_in          => csr_addr_in,
      csr_addr_out         => csr_addr_to_stg2,
      csr_write_in         => csr_write_in,
      csr_write_out        => csr_write_to_stg2,
      csr_value_in         => csr_value_in,
      csr_value_out        => csr_value_to_stg2,
      csr_use_immediate_in => csr_use_immediate_in,

      -- Control signals:
      alu_op_in    => alu_op_in,
      alu_op_out   => alu_op_to_stg2,
      alu_x_src_in => alu_x_src_in,
      alu_y_src_in => alu_y_src_in,
      rd_write_in  => rd_write_in,
      rd_write_out => rd_write_to_stg2,
      branch_in    => branch_in,
      branch_out   => branch_to_stg2,

      -- Memory control signals:
      mem_op_in    => mem_op_in,
      mem_op_out   => mem_op_to_stg2,
      mem_size_in  => mem_size_in,
      mem_size_out => mem_size_to_stg2,

      -- Whether the instruction should be counted:
      count_instruction_in  => count_instruction_in,
      count_instruction_out => count_instruction_to_stg2,

      -- Exception control registers:
      ie_in     => ie_in,
      ie1_in    => ie1_in,
      mie_in    => mie_in,
      mtvec_in  => mtvec_in,
      mtvec_out => mtvec_to_stg2,
      --mepc_in       : in  std_logic_vector(31 downto 0);

      -- Exception signals:
      decode_exception_in       => decode_exception_in,
      decode_exception_cause_in => decode_exception_cause_in,

      -- Exception outputs:
      exception_out         => exception_to_stg2,
      exception_context_out => exception_context_to_stg2,

      -- Control outputs:
      jump_out        => jump_out,
      jump_target_out => jump_target_out
    );

  exe_stg2_instance : entity work.fp_exe_stg2
    port
    map(
    clk   => clk,
    reset => reset,
    stall => stall_exe_stg2,

    -- Data memory outputs:
    x_sign_in => x_sign_to_stg2,
    x_data_in => x_data_to_stg2,
    y_sign_in => y_sign_to_stg2,
    y_data_in => y_data_to_stg2,

    -- rd_data_forwarded_x = >,
    -- rd_data_forwarded_y = >,

    -- Data memory outputs:
    dmem_address_in   => dmem_address_to_stg2,
    dmem_data_in      => dmem_data_to_stg2,
    dmem_data_size_in => dmem_data_size_to_stg2,
    dmem_read_req_in  => dmem_read_req_to_stg2,
    dmem_write_req_in => dmem_write_req_to_stg2,

    -- Register addresses:
    rd_addr_in => rd_addr_to_stg2,

    -- Register values:
    rd_data_in => rd_data_to_stg2,

    -- Instruction address:
    pc_in => pc_to_stg2,

    -- CSR signals:
    csr_addr_in  => csr_addr_to_stg2,
    csr_write_in => csr_write_to_stg2,
    csr_value_in => csr_value_to_stg2,

    -- csd alu inputs
    alu_op_in => alu_op_to_stg2,
    alu_y_in  => alu_y_to_stg2,

    -- Control signals:
    rd_write_in => rd_write_to_stg2,
    branch_in   => branch_to_stg2,

    -- Memory control signals:
    mem_op_in   => mem_op_to_stg2,
    mem_size_in => mem_size_to_stg2,

    -- Whether the instruction should be counted:
    count_instruction_in => count_instruction_to_stg2,

    -- Exception control registers:
    mtvec_in => mtvec_to_stg2,

    -- Exception outputs:
    exception_in         => exception_to_stg2,
    exception_context_in => exception_context_to_stg2,

    -- Data memory outputs:
    dmem_address_out   => dmem_address_to_stg3,
    dmem_data_out      => dmem_data_to_stg3,
    dmem_data_size_out => dmem_data_size_to_stg3,
    dmem_read_req_out  => dmem_read_req_to_stg3,
    dmem_write_req_out => dmem_write_req_to_stg3,

    -- Register addresses:
    rd_addr_out => rd_addr_to_stg3,

    -- Register values:
    rd_data_out => bw_alu_result_to_stg3,
    Pst_result  => Pst_result_to_stg3,
    Ngt_result  => Ngt_result_to_stg3,
    
    W1_out => W1_to_stg3,
    W2_out => W2_to_stg3,
    W3_out => W3_to_stg3,
    W4_out => W4_to_stg3,
    Lpp_out => Lpp_to_stg3,
    -- Instruction address:
    pc_out => pc_to_stg3,

    -- CSR signals:
    csr_addr_out  => csr_addr_to_stg3,
    csr_write_out => csr_write_to_stg3,
    csr_value_out => csr_value_to_stg3,

    alu_op_out => alu_op_to_stg3,

    -- Control signals:
    rd_write_out => rd_write_to_stg3,
    branch_out   => branch_to_stg3,

    -- Memory control signals:
    mem_op_out   => mem_op_to_stg3,
    mem_size_out => mem_size_to_stg3,

    -- Whether the instruction should be counted:
    count_instruction_out => count_instruction_to_stg3,

    -- Exception control registers:
    mtvec_out => mtvec_to_stg3,

    -- Exception outputs:
    exception_out         => exception_to_stg3,
    exception_context_out => exception_context_to_stg3

    );

  exe_stg3_instance : entity work.fp_exe_stg3
    port
    map(
    clk   => clk,
    reset => reset,
    stall => stall_exe_stg2,

    -- Data memory outputs:
    dmem_address_in   => dmem_address_to_stg3,
    dmem_data_in      => dmem_data_to_stg3,
    dmem_data_size_in => dmem_data_size_to_stg3,
    dmem_read_req_in  => dmem_read_req_to_stg3,
    dmem_write_req_in => dmem_write_req_to_stg3,

    -- Register addresses:
    rd_addr_in => rd_addr_to_stg3,

    -- Register values:
    bw_rd_data_in  => bw_alu_result_to_stg3,
    Pst_result_in  => Pst_result_to_stg3,
    Ngt_result_in  => Ngt_result_to_stg3,
    
    W1_in => W1_to_stg3,
    W2_in => W2_to_stg3,
    W3_in => W3_to_stg3,
    W4_in => W4_to_stg3,
    Lpp_in=> Lpp_to_stg3,

    -- Instruction address:
    pc_in => pc_to_stg3,

    -- CSR signals:
    csr_addr_in  => csr_addr_to_stg3,
    csr_write_in => csr_write_to_stg3,
    csr_value_in => csr_value_to_stg3,

    -- csd alu inputs
    alu_op_in => alu_op_to_stg3,

    -- Control signals:
    rd_write_in => rd_write_to_stg3,
    branch_in   => branch_to_stg3,

    -- Memory control signals:
    mem_op_in   => mem_op_to_stg3,
    mem_size_in => mem_size_to_stg3,

    -- Whether the instruction should be counted:
    count_instruction_in => count_instruction_to_stg3,

    -- Exception control registers:
    mtvec_in => mtvec_to_stg3,

    -- Exception outputs:
    exception_in         => exception_to_stg3,
    exception_context_in => exception_context_to_stg3,

    -- Data memory outputs:
    dmem_address_out   => dmem_address,
    dmem_data_out      => dmem_data_out,
    dmem_data_size_out => dmem_data_size,
    dmem_read_req_out  => dmem_read_req,
    dmem_write_req_out => dmem_write_req,

    -- Register addresses:
    rd_addr_out => rd_addr_to_forwarding_stg3,

    -- Register values:
    rd_data_out     => rd_data_out,
    bw_rd_data_out  => bw_to_forwarding_stg3,
    --csd_rd_data_out => csd_to_forwarding_stg3,

    -- Instruction address:
    pc_out => pc_out,

    -- CSR signals:
    csr_addr_out  => csr_addr_out,
    csr_write_out => csr_write_to_hazard_stg3,
    csr_value_out => csr_value_out,

    alu_op_out => alu_op_to_forwarding_stg3,

    -- Control signals:
    rd_write_out => rd_write_to_forwarding_stg3,
    branch_out   => branch_out,

    -- Memory control signals:
    mem_op_out   => mem_op_to_hazard_stg3,
    mem_size_out => mem_size_out,

    -- Whether the instruction should be counted:
    count_instruction_out => count_instruction_out,

    -- Exception control registers:
    mtvec_out => mtvec_out,

    -- Exception outputs:
    exception_out         => exception_to_hazard_stg3,
    exception_context_out => exception_context_out

    );

  alu_x_forward : process (rd_write_to_forwarding_stg3, bw_to_forwarding_stg3, rd_addr_to_forwarding_stg3, rd_write_to_stg3, bw_alu_result_to_stg3, rd_addr_to_stg3, mem_rd_write, mem_rd_value, mem_rd_addr, rs1_addr,
    rs1_data, wb_rd_write, wb_rd_addr, wb_rd_value)
  begin
    if rd_write_to_forwarding_stg3 = '1' and rd_addr_to_forwarding_stg3 = rs1_addr and rd_addr_to_forwarding_stg3 /= b"00000" then
      rs1_forwarded <= bw_to_forwarding_stg3;
    elsif rd_write_to_stg3 = '1' and rd_addr_to_stg3 = rs1_addr and rd_addr_to_stg3 /= b"00000" then
      rs1_forwarded <= bw_alu_result_to_stg3;
    elsif mem_rd_write = '1' and mem_rd_addr = rs1_addr and mem_rd_addr /= b"00000" then
      rs1_forwarded <= mem_rd_value;
    elsif wb_rd_write = '1' and wb_rd_addr = rs1_addr and wb_rd_addr /= b"00000" then
      rs1_forwarded <= wb_rd_value;
    else
      rs1_forwarded <= rs1_data;
    end if;
  end process alu_x_forward;

  alu_y_forward : process (rd_write_to_forwarding_stg3, bw_to_forwarding_stg3, rd_addr_to_forwarding_stg3,rd_write_to_stg3, bw_alu_result_to_stg3, rd_addr_to_stg3, mem_rd_write, mem_rd_value, mem_rd_addr, rs2_addr, rs2_data, wb_rd_write, wb_rd_addr, wb_rd_value)
  begin
    if rd_write_to_forwarding_stg3 = '1' and rd_addr_to_forwarding_stg3 = rs2_addr and rd_addr_to_forwarding_stg3 /= b"00000" then
      rs2_forwarded <= bw_to_forwarding_stg3;
    elsif rd_write_to_stg3 = '1' and rd_addr_to_stg3 = rs2_addr and rd_addr_to_stg3 /= b"00000" then
      rs2_forwarded <= bw_alu_result_to_stg3;
    elsif mem_rd_write = '1' and mem_rd_addr = rs2_addr and mem_rd_addr /= b"00000" then
      rs2_forwarded <= mem_rd_value;
    elsif wb_rd_write = '1' and wb_rd_addr = rs2_addr and wb_rd_addr /= b"00000" then
      rs2_forwarded <= wb_rd_value;
    else
      rs2_forwarded <= rs2_data;
    end if;
  end process alu_y_forward;

  -- stall entire of decode to execution stage 1 for 1 cycle 

  detect_load_hazard : process (mem_op_to_hazard_stg3, rd_addr_to_forwarding_stg3,mem_op_to_stg3, rd_addr_to_stg3, mem_mem_op, mem_rd_addr, rs1_addr, rs2_addr, alu_x_src, alu_y_src)
  begin
  
      load_hazard_detected <= '0';
      
    if (mem_mem_op = MEMOP_TYPE_LOAD or mem_mem_op = MEMOP_TYPE_LOAD_UNSIGNED) and
      ((alu_x_src = ALU_SRC_REG and mem_rd_addr = rs1_addr and rs1_addr /= b"00000") or (alu_y_src = ALU_SRC_REG and mem_rd_addr = rs2_addr and rs2_addr /= b"00000"))then
      
      load_hazard_detected <= '1';
    
    elsif (mem_op_to_hazard_stg3 = MEMOP_TYPE_LOAD or mem_op_to_hazard_stg3 = MEMOP_TYPE_LOAD_UNSIGNED) and
    ((alu_x_src = ALU_SRC_REG and rd_addr_to_forwarding_stg3 = rs1_addr and rs1_addr /= b"00000") or (alu_y_src = ALU_SRC_REG and rd_addr_to_forwarding_stg3 = rs2_addr and rs2_addr /= b"00000")) then
    
    load_hazard_detected <= '1';
    
    elsif (mem_op_to_stg3 = MEMOP_TYPE_LOAD or mem_op_to_stg3 = MEMOP_TYPE_LOAD_UNSIGNED) and
      ((alu_x_src = ALU_SRC_REG and rd_addr_to_stg3 = rs1_addr and rs1_addr /= b"00000") or (alu_y_src = ALU_SRC_REG and rd_addr_to_stg3 = rs2_addr and rs2_addr /= b"00000")) then
      
      load_hazard_detected <= '1';
    
    end if;
  end process detect_load_hazard;

  detect_csr_hazard : process (csr_write_to_stg3, csr_write_to_hazard_stg3, mem_csr_write, wb_csr_write,exception_to_stg3, exception_to_hazard_stg3, mem_exception, wb_exception)
  begin
  
    csr_hazard_detected <= '0';
    
    if csr_write_to_stg3/=CSR_WRITE_NONE or csr_write_to_hazard_stg3 /= CSR_WRITE_NONE or mem_csr_write /= CSR_WRITE_NONE or wb_csr_write /= CSR_WRITE_NONE
      or exception_to_stg3='1' or exception_to_hazard_stg3 = '1' or mem_exception = '1' or wb_exception = '1' then
      csr_hazard_detected <= '1';
    end if;
  end process detect_csr_hazard;


  detect_csd_instr_hazard : process (alu_op_to_forwarding_stg3, rd_write_to_forwarding_stg3, rd_addr_to_forwarding_stg3, alu_op_to_stg3, rd_write_to_stg3, rd_addr_to_stg3, rs1_addr, rs2_addr)
  begin
    
    csd_instruction_hazard <= '0';
    
    if (rd_write_to_forwarding_stg3 = '1' and (rd_addr_to_forwarding_stg3 = rs1_addr or rd_addr_to_forwarding_stg3 = rs2_addr) and rd_addr_to_forwarding_stg3 /= b"00000") then
      if (alu_op_to_forwarding_stg3 = ALU_ADD or
          alu_op_to_forwarding_stg3 = ALU_SUB or
          alu_op_to_forwarding_stg3 = ALU_MUL or
          alu_op_to_forwarding_stg3 = ALU_MULH or
          alu_op_to_forwarding_stg3 = ALU_MULHU or
          alu_op_to_forwarding_stg3 = ALU_MULHSU) then
      
                csd_instruction_hazard <= '1';
            
       end if;
     end if;
    
    if (rd_write_to_stg3 = '1' and (rd_addr_to_stg3 = rs1_addr or rd_addr_to_stg3 = rs2_addr) and rd_addr_to_stg3 /= b"00000") then
        if (alu_op_to_stg3 = ALU_ADD or 
            alu_op_to_stg3 = ALU_SUB or 
            alu_op_to_stg3 = ALU_MUL or  
            alu_op_to_stg3 = ALU_MULH or 
            alu_op_to_stg3 = ALU_MULHU or 
            alu_op_to_stg3 = ALU_MULHSU) then
          
                csd_instruction_hazard <= '1';
                
        end if;
    end if;
    
  end process detect_csd_instr_hazard;

  hazard_detected <= load_hazard_detected or csr_hazard_detected or csd_instruction_hazard;

end architecture behaviour;
