----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.03.2026 15:53:10
-- Design Name: 
-- Module Name: EXEC_TOP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EXEC_TOP is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC);
end EXEC_TOP;

architecture Behavioral of EXEC_TOP is

signal A : std_logic_vector(31 downto 0) := x"40490FDA" ;
signal B  : std_logic_vector(31 downto 0) := x"402DF84D";
signal stall : std_logic := '0';






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
 signal div_rm_to_s2 : std_logic_vector(2 downto 0);


begin


fpu_stg1: entity work.fpu_stage1
    port map (
        clk       => clk,       
        reset   => reset,         
        stall    => stall,            
        ex_stall => '0',            
        start   => '1',               -- Division start signal

         en_fadd_in  => '0',    
         en_fsub_in => '0',     
         en_fmul_in  => '0',    
         en_fdiv_in  => '0',    



       -- alu_op_in    ---- add or sub or mul or div or etc
        
        -- Operands and control
        operand1   => A,           
        operand2   => B,                     ------- 

        rm       =>   "000",            
        
        -- Division latched operands
        div_operand1   => A,           
        div_operand2   => B,           
        div_rm_in       =>"000",
        
        -- ADD Stage 1 outputs
      add_A_sign => add_A_sign_to_stg2,
      add_B_sign => add_B_sign_to_stg2,
      add_A_exp => add_A_exp_to_stg2,
      add_B_exp => add_B_exp_to_stg2,
      add_A_mant => add_A_mant_to_stg2,
      add_B_mant => add_B_mant_to_stg2,
      add_rm => add_rm_to_stg2,
      add_valid => add_valid_out_s1,  -----add_valid_to_stg2 need to add
      
      -- SUB Stage 1 outputs
      sub_A_sign => sub_A_sign_to_stg2,
      sub_B_sign => sub_B_sign_to_stg2,
      sub_A_exp => sub_A_exp_to_stg2,
      sub_B_exp => sub_B_exp_to_stg2,
      sub_A_mant => sub_A_mant_to_stg2,
      sub_B_mant => sub_B_mant_to_stg2,
      sub_rm => sub_rm_to_stg2,
      
      -- MUL Stage 1 outputs
      mul_A_sign => mul_A_sign_to_stg2,
      mul_B_sign => mul_B_sign_to_stg2,
      mul_A_exp => mul_A_exp_to_stg2,
      mul_B_exp => mul_B_exp_to_stg2,
      mul_A_frac => mul_A_frac_to_stg2,
      mul_B_frac => mul_B_frac_to_stg2,
      mul_A_mant => mul_A_mant_to_stg2,
      mul_B_mant => mul_B_mant_to_stg2,
      mul_rm => mul_rm_to_stg2,
      
      -- DIV Stage 1 outputs
      div_x_val => div_x_val_to_stg2,
      div_y_val => div_y_val_to_stg2,
      div_exp => div_exp_to_stg2,
      div_sign => div_sign_to_stg2,
      div_special => div_special_to_stg2,
      div_special_result => div_special_result_to_stg2,
      div_valid => div_valid_to_stg2,   ----important
      div_rm => div_rm_to_s2
  
        
    );





    -- FPU Stage 2 instantiation
  fpu_stg2_instance : entity work.fpu_stage2
    port map(
      clk => clk,
      reset => reset,
      stall => internal_stall,
      ex_stall => stall,
      ----alu_op_in => alu_op,

      
      en_fadd_in => en_fadd_reg,
      en_fsub_in => en_fsub_reg,
      en_fmul_in => en_fmul_reg,
      en_fdiv_in => en_fdiv_reg,
      
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
      mul_A_sign => mul_A_sign,
      mul_B_sign => mul_B_sign,
      mul_A_exp => mul_A_exp,
      mul_B_exp => mul_B_exp,
      mul_A_frac => mul_A_frac,
      mul_B_frac => mul_B_frac,
      mul_A_mant => mul_A_mant,
      mul_B_mant => mul_B_mant,
      mul_rm => mul_rm,
      
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


end Behavioral;
