--==============================================================================
-- FPU STAGE 1 WRAPPER (VHDL) - CORRECTED
-- Parallel FADD, FSUB, FMUL, FDIV Stage 1 operations
-- Outputs all results separately for external muxing
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

entity fpu_stage1 is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        stall            : in  std_logic;
        ex_stall         : in  std_logic;
        start            : in  std_logic;  -- Division start signal

         en_fadd : in std_logic;
         en_fsub : in std_logic;
         en_fmul : in std_logic;
         en_fdiv : in std_logic;



       -- alu_op_in : in alu_operation;   ---- add or sub or mul or div or etc
        
        -- Operands and control
        operand1         : in  std_logic_vector(31 downto 0);    ------- frs1_forwareded
        operand2         : in  std_logic_vector(31 downto 0);     ------- frs2_forwarded

        rm               : in  std_logic_vector(2 downto 0);
        
        -- Division latched operands
        div_operand1     : in  std_logic_vector(31 downto 0);
        div_operand2     : in  std_logic_vector(31 downto 0);
        div_rm_in        : in  std_logic_vector(2 downto 0);
        
        -- ADD Stage 1 outputs
        add_A_sign       : out std_logic;
        add_B_sign       : out std_logic;
        add_A_exp        : out std_logic_vector(7 downto 0);
        add_B_exp        : out std_logic_vector(7 downto 0);
        add_A_mant       : out std_logic_vector(26 downto 0); -- 27 bits
        add_B_mant       : out std_logic_vector(26 downto 0); -- 27 bits
        add_rm           : out std_logic_vector(2 downto 0);
        add_valid        : out std_logic;
        
        -- SUB Stage 1 outputs
        sub_A_sign       : out std_logic;
        sub_B_sign       : out std_logic;
        sub_A_exp        : out std_logic_vector(7 downto 0);
        sub_B_exp        : out std_logic_vector(7 downto 0);
        sub_A_mant       : out std_logic_vector(26 downto 0); -- 27 bits
        sub_B_mant       : out std_logic_vector(26 downto 0); -- 27 bits
        sub_rm           : out std_logic_vector(2 downto 0);
        
        -- MUL Stage 1 outputs
        mul_A_sign       : out std_logic;
        mul_B_sign       : out std_logic;
        mul_A_exp        : out std_logic_vector(7 downto 0);
        mul_B_exp        : out std_logic_vector(7 downto 0);
        mul_A_frac       : out std_logic_vector(22 downto 0);
        mul_B_frac       : out std_logic_vector(22 downto 0);
        mul_A_mant       : out std_logic_vector(26 downto 0); -- Padded to 27 externally
        mul_B_mant       : out std_logic_vector(26 downto 0); -- Padded to 27 externally
        mul_rm           : out std_logic_vector(2 downto 0);
        
        -- DIV Stage 1 outputs
        div_x_val        : out std_logic_vector(31 downto 0);
        div_y_val        : out std_logic_vector(31 downto 0);
        div_exp          : out std_logic_vector(7 downto 0);
        div_sign         : out std_logic;
        div_special      : out std_logic;
        div_special_result : out std_logic_vector(31 downto 0);
         
        div_valid        : out std_logic;
        div_rm           : out std_logic_vector(2 downto 0)
        
       
        
    );
end entity fpu_stage1;

architecture rtl of fpu_stage1 is



begin


    ----------------------------------------------------------------------------
    -- Instantiate FADD Stage 1
    ----------------------------------------------------------------------------
    add_stage1 : entity work.ieee754_adder_stage1
        port map (
            clk    => clk,
            reset  => reset,
            stall  => stall,
            ex_stall => ex_stall,
            en_fadd  => en_fadd,
            A      => operand1,
            B      => operand2,
            rm     => rm,
            A_sign => add_A_sign,
            B_sign => add_B_sign,
            A_exp  => add_A_exp,
            B_exp  => add_B_exp,
            A_mant => add_A_mant,
            B_mant => add_B_mant,
            s1_valid => add_valid,
            rm_out => add_rm
            --alu_op_in => ALU_FADD
        );

    ----------------------------------------------------------------------------
    -- Instantiate FSUB Stage 1
    ----------------------------------------------------------------------------
    sub_stage1 : entity work.ieee754_subtractor_stage1
        port map (
            clk    => clk,
            reset  => reset,
            stall  => stall,
            ex_stall => ex_stall,
            en_fsub  => en_fsub,
            A      => operand1,
            B      => operand2,
            rm     => rm,
            A_sign => sub_A_sign,
            B_sign => sub_B_sign,
            A_exp  => sub_A_exp,
            B_exp  => sub_B_exp,
            A_mant => sub_A_mant,
            B_mant => sub_B_mant,
            rm_out => sub_rm
            --alu_op_in => ALU_FSUB
        );

    ----------------------------------------------------------------------------
    -- Instantiate FMUL Stage 1
    ----------------------------------------------------------------------------
    mul_stage1 : entity work.ieee754mult_stage1
        port map (
            clk    => clk,
            reset  => reset,
            stall  => stall,
            ex_stall => ex_stall,
             
            en_fmul  => en_fmul,
            A      => operand1,
            B      => operand2,
            rm     => rm,
            A_sign => mul_A_sign,
            B_sign => mul_B_sign,
            A_exp  => mul_A_exp,
            B_exp  => mul_B_exp,
            A_frac => mul_A_frac,
            B_frac => mul_B_frac,
            A_mant => mul_A_mant(23 downto 0),
            B_mant => mul_B_mant(23 downto 0),
            rm_out => mul_rm
            --alu_op_in => ALU_FMUL
        );

    ----------------------------------------------------------------------------
    -- Instantiate FDIV Stage 1
    ----------------------------------------------------------------------------
    div_stage1 : entity work.ieee754_div_stage1
        port map (
            clk            => clk,
            reset          => reset,
            a              => div_operand1,
            b              => div_operand2,
            start          => start,
            rm             => div_rm_in,
            en_fdiv        => en_fdiv,
            x_val          => div_x_val,
            y_val          => div_y_val,
            result_exp     => div_exp,
            result_sign    => div_sign,
            special_case   => div_special,
            special_result => div_special_result,
            s1_valid          => div_valid,   ------need to check the flow
            rm_out        => div_rm
            --alu_op_in => ALU_FDIV
        );

    
    

end architecture rtl;