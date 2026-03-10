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



 -- FPU Stage 1 all 4 operation outputs (for parallel computation in Stage 2)
    -- ADD Stage 1 outputs
signal add_A_sign_out : std_logic;
signal add_B_sign_out : std_logic;
signal add_A_exp_out : std_logic_vector(7 downto 0);
signal add_B_exp_out : std_logic_vector(7 downto 0);
signal add_A_mant_out : std_logic_vector(26 downto 0);
signal add_B_mant_out : std_logic_vector(26 downto 0);
signal add_rm_out :  std_logic_vector(2 downto 0);
signal add_valid_out :     std_logic;
signal 
signal -- SUB Stage 1 outputs
signal sub_A_sign_out :     std_logic;
signal sub_B_sign_out :     std_logic;
signal sub_A_exp_out :     std_logic_vector(7 downto 0);
signal sub_B_exp_out :     std_logic_vector(7 downto 0);
signal sub_A_mant_out :     std_logic_vector(26 downto 0);
signal sub_B_mant_out :     std_logic_vector(26 downto 0);
signal sub_rm_out :     std_logic_vector(2 downto 0);
signal 
signal -- MUL Stage 1 outputs (including fractions)
signal mul_A_sign_out :     std_logic;
signal mul_B_sign_out :     std_logic;
signal mul_A_exp_out :     std_logic_vector(7 downto 0);
signal mul_B_exp_out :     std_logic_vector(7 downto 0);
signal mul_A_frac_out :     std_logic_vector(22 downto 0);  -- Raw fraction for NaN/Inf detection
signal mul_B_frac_out :     std_logic_vector(22 downto 0);
signal mul_A_mant_out :     std_logic_vector(26 downto 0);
signal mul_B_mant_out :     std_logic_vector(26 downto 0);
signal mul_rm_out :     std_logic_vector(2 downto 0);
signal 
signal -- DIV Stage 1 outputs
signal div_x_val_out :     std_logic_vector(31 downto 0);
signal div_y_val_out :     std_logic_vector(31 downto 0);
signal div_exp_out :     std_logic_vector(7 downto 0);
signal div_sign_out :     std_logic;
signal div_special_out :     std_logic;
signal div_special_result_out :     std_logic_vector(31 downto 0);
signal div_valid_out :     std_logic;
signal div_rm_out :     std_logic_vector(2 downto 0);


begin


fpu_stg1: entity work.fpu_stage1
    port map (
        clk      <= clk,       
        reset   <= reset,         
        stall    <= stall,            
        ex_stall <= '0',            
        start   <= '1',               -- Division start signal

         en_fadd_in <= '0',    
         en_fsub_in <= '0',     
         en_fmul_in  <= '0',    
         en_fdiv_in  <= '0',    



       -- alu_op_in    ---- add or sub or mul or div or etc
        
        -- Operands and control
        operand1   <= A,           
        operand2   <= B,                     ------- 

        rm       <=   '0',            
        
        -- Division latched operands
        div_operand1   <= A,           
        div_operand2   <= '0',           
        --div_rm_in       
        
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



end Behavioral;
