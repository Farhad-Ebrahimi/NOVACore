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
    dmem_data_size_in : in std_logic_vector(1 downto 0);
    dmem_read_req_in  : in std_logic;
    dmem_write_req_in : in std_logic;

    -- Register addresses:
    rd_addr_in : in register_address;

    -- Register values:
    rd_data_in : in std_logic_vector(31 downto 0);

    -- Instruction address:
    pc_in : in std_logic_vector(31 downto 0);

    -- CSR signals:
    csr_addr_in  : in csr_address;
    csr_write_in : in csr_write_mode;
    csr_value_in : in std_logic_vector(31 downto 0);

    -- csd alu inputs
    alu_op_in  : in alu_operation;
    alu_op_out : out alu_operation;
    alu_y_in  : in std_logic_vector(31 downto 0);

    -- Divider inputs
    a_sign_in        : in std_logic;
    b_sign_in        : in std_logic;
    a_norm_in        : in std_logic_vector(31 downto 0);
    b_norm_in        : in std_logic_vector(31 downto 0);
    shift_a_in       : in unsigned(4 downto 0);
    shift_b_in       : in unsigned(4 downto 0);
    div_by_zero_in   : in std_logic;
    div_overflow_in  : in std_logic;

    -- Divider outputs
    a_sign_out           : out std_logic;
    b_sign_out           : out std_logic;
    shift_a_out          : out unsigned(4 downto 0);
    shift_b_out          : out unsigned(4 downto 0);
    div_by_zero_out      : out std_logic;
    div_overflow_out     : out std_logic;
    q_pos_out, q_neg_out : out std_logic_vector(33 downto 0);
    r_pos_out, r_neg_out : out std_logic_vector(33 downto 0);

    stall_srt_div : out std_logic;

    -- Control signals:
    rd_write_in : in std_logic;
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
    dmem_data_size_out : out std_logic_vector(1 downto 0);
    dmem_read_req_out  : out std_logic;
    dmem_write_req_out : out std_logic;

    -- Register addresses:
    rd_addr_out : out register_address;

    -- Register values:
    Pst_result  : out std_logic_vector(31 downto 0);
    Ngt_result  : out std_logic_vector(31 downto 0);
    
    W1_out  : out std_logic_vector(83 downto 0);
    W2_out  : out std_logic_vector(83 downto 0);
    W3_out  : out std_logic_vector(83 downto 0);
    W4_out  : out std_logic_vector(83 downto 0);
    Lpp_out  : out std_logic_vector(67 downto 0);
    
    rd_data_out : out std_logic_vector(31 downto 0);

    -- Instruction address:
    pc_out : out std_logic_vector(31 downto 0);

    -- CSR signals:
    csr_addr_out  : out csr_address;
    csr_write_out : out csr_write_mode;
    csr_value_out : out std_logic_vector(31 downto 0);

    -- Control signals:
    rd_write_out : out std_logic;
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
  signal dmem_data_size : std_logic_vector(1 downto 0);
  signal dmem_write_req     : std_logic;
  signal dmem_read_req      : std_logic;
  
  signal x_sign : std_logic_vector(32 downto 0);
  signal x_data : std_logic_vector(32 downto 0);
  signal y_sign : std_logic_vector(32 downto 0);
  signal y_data : std_logic_vector(32 downto 0);

  -- SRT division
  signal srt_div_running : std_logic;

  signal a_sign        : std_logic;
  signal b_sign        : std_logic;
  signal a_norm        : std_logic_vector(31 downto 0);
  signal b_norm        : std_logic_vector(31 downto 0);
  signal shift_a       : unsigned(4 downto 0);
  signal shift_b       : unsigned(4 downto 0);
  signal div_by_zero   : std_logic;
  signal div_overflow  : std_logic;

  signal a_pos_in, a_neg_in : std_logic_vector(33 downto 0);
  signal b_pos_in, b_neg_in : std_logic_vector(33 downto 0);
  signal q_pos_in, q_neg_in : std_logic_vector(33 downto 0);

  signal a_pos, a_neg : std_logic_vector(33 downto 0);
  signal b_pos, b_neg : std_logic_vector(33 downto 0);
  signal q_pos, q_neg : std_logic_vector(33 downto 0);

  signal counter_in  : std_logic_vector(5 downto 0);
  signal counter_out : std_logic_vector(5 downto 0);

  signal rd_addr_saved : register_address;
  signal rd_data_saved : std_logic_vector(31 downto 0);

  -- signal Pst_result     : std_logic_vector(31 downto 0);
  -- signal Ngt_result     : std_logic_vector(31 downto 0);
  
begin

  -- Register values should not be latched in by a clocked process,
  -- this is already done in the register files.
  csr_value_out<=csr_value;
  rd_data_out <= bw_alu_result;

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
  dmem_data_size_out <= dmem_data_size;
  dmem_write_req_out <= dmem_write_req;
  dmem_read_req_out  <= dmem_read_req;


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

        counter_in <= "000000";
        srt_div_running <= '0';
        stall_srt_div <= '0';

      elsif stall = '0' and srt_div_running = '0' then
        pc                    <= pc_in;
        count_instruction_out <= count_instruction_in;
        
        -- Register signals:
        rd_write_out  <= rd_write_in;
        rd_addr_out   <= rd_addr_in;
        bw_alu_result <= rd_data_in;
        
        -- CSD ALU signals:
        alu_op   <= alu_op_in;
                
        -- CSD ALU inputs:
        x_sign <= x_sign_in;
        x_data <= x_data_in;
        y_sign <= y_sign_in;
        y_data <= y_data_in;
        alu_y   <= alu_y_in;

        -- Divider inputs
        a_sign <= a_sign_in;
        b_sign <= b_sign_in;
        a_norm <= a_norm_in;
        b_norm <= b_norm_in;
        shift_a <= shift_a_in;
        shift_b <= shift_b_in;
        div_by_zero <= div_by_zero_in;
        div_overflow <= div_overflow_in;
        
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
        dmem_data_size <= dmem_data_size_in;
        dmem_write_req <= dmem_write_req_in;
        dmem_read_req  <= dmem_read_req_in;

        -- division logic
        if (alu_op_in = ALU_DIV or alu_op_in = ALU_DIVU) then
          srt_div_running <= '1';
          stall_srt_div <= '1';
          counter_in <= "000000";

          rd_addr_saved <= rd_addr_in;
          rd_data_saved <= rd_data_in;

          a_pos_in <= "00" & a_norm_in;
          a_neg_in <= (others => '0');
          b_pos_in <= "00" & b_norm_in;
          b_neg_in <= (others => '0');
          q_pos_in <= (others => '0');
          q_neg_in <= (others => '0');
        end if;

      elsif stall = '0' and srt_div_running = '1' then
        counter_in <= counter_out;

        a_pos_in <= a_pos;
        a_neg_in <= a_neg;
        b_pos_in <= b_pos;
        b_neg_in <= b_neg;
        q_pos_in <= q_pos;
        q_neg_in <= q_neg;

        if (counter_in = "011111") then
          stall_srt_div <= '0';
          srt_div_running <= '0';
        end if;
      end if;
    end if;
  end process pipeline_register;
  
  -- csd_alu_result<= std_logic_vector(unsigned(Pst_result) + unsigned(Ngt_result) + 1);

  csd_alu_instance : entity work.csd_alu
    port map(
      y         => alu_y,
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

  divider: entity work.divider
    port map (
      a_pos => a_pos_in,
      a_neg => a_neg_in,
      b_pos => b_pos_in,
      b_neg => b_neg_in,
      q_pos => q_pos_in,
      q_neg => q_neg_in,
      a_pos_out => a_pos,
      a_neg_out => a_neg,
      b_pos_out => b_pos,
      b_neg_out => b_neg,
      q_pos_out => q_pos,
      q_neg_out => q_neg,
      counter_in => counter_in,
      counter_out => counter_out
    );

  q_pos_out <= q_pos;
  q_neg_out <= q_neg;

  a_sign_out <= a_sign;
  b_sign_out <= b_sign;
  shift_a_out <= shift_a;
  shift_b_out <= shift_b;
  div_by_zero_out <= div_by_zero;
  div_overflow_out <= div_overflow;
end architecture behaviour;
