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

    -- Data memory outputs:
    dmem_address_in   : in std_logic_vector(31 downto 0);
    dmem_data_in      : in std_logic_vector(31 downto 0);
    dmem_data_size_in : in std_logic_vector(1 downto 0);
    dmem_read_req_in  : in std_logic;
    dmem_write_req_in : in std_logic;

    -- Register addresses:
    rd_addr_in : in register_address;

    -- Register values:
    Pst_result_in : in std_logic_vector(31 downto 0);
    Ngt_result_in : in std_logic_vector(31 downto 0);
    
    W1_in  : in std_logic_vector(83 downto 0);
    W2_in  : in std_logic_vector(83 downto 0);
    W3_in  : in std_logic_vector(83 downto 0);
    W4_in  : in std_logic_vector(83 downto 0);
    Lpp_in : in std_logic_vector(67 downto 0);
    
    bw_rd_data_in    : in std_logic_vector(31 downto 0);

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
    rd_data_out : out std_logic_vector(31 downto 0);
    bw_rd_data_out : out std_logic_vector(31 downto 0);
    --sd_rd_data_out : out std_logic_vector(63 downto 0);
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

  signal Pos_Add     : std_logic_vector(31 downto 0);
  signal Neg_Add     : std_logic_vector(31 downto 0);
  
  signal Pos_mul     : std_logic_vector(63 downto 0);
  signal Neg_mul     : std_logic_vector(63 downto 0);
  
  signal W1, W2, W3, W4 : std_logic_vector(83 downto 0);
  signal Lpp : std_logic_vector(67 downto 0);
  
begin

  -- Register values should not be latched in by a clocked process,
  -- this is already done in the register files.
  csr_value_out<=csr_value;
  rd_data_out <= alu_result;
  bw_rd_data_out <= bw_alu_result;

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

  dmem_address_out   <=  alu_result when (mem_op /= MEMOP_TYPE_NONE and mem_op /= MEMOP_TYPE_INVALID) and exception = '0'else dmem_address;
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
      elsif stall = '0' then
      
        pc                    <= pc_in;
        count_instruction_out <= count_instruction_in;
        
        -- Register signals:
        rd_write_out  <= rd_write_in;
        rd_addr_out   <= rd_addr_in;
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
  
    process (alu_op,csd_alu_result_HL,csd_alu_result_AS,bw_alu_result)
     begin
       case alu_op is
            when ALU_MUL =>
                alu_result <= csd_alu_result_HL(31 downto 0);
            when ALU_MULH | ALU_MULHU | ALU_MULHSU =>
                alu_result <= csd_alu_result_HL(63 downto 32);
            when ALU_ADD | ALU_SUB =>
                alu_result <= csd_alu_result_AS;
            when ALU_SLT | ALU_SLTU | ALU_AND | ALU_OR | ALU_XOR | ALU_SLL | ALU_SRL |ALU_SRA =>
                alu_result <= bw_alu_result;  
            when others =>
                alu_result <= (others=>'0');  
        end case;
     end process;
    
end architecture behaviour;
