--==============================================================================
-- FPU STAGE 2 WRAPPER (VHDL)
-- Parallel FADD, FSUB, FMUL, FDIV Stage 2 operations
-- Outputs all results separately for external muxing
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

entity fpu_stage2 is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        stall            : in  std_logic;

         en_fadd : in std_logic;
         en_fsub : in std_logic;
         en_fmul : in std_logic;
         en_fdiv : in std_logic;

        --alu_op_in        : in alu_operation;   ---- add or sub or mul or div or etc
        -- CSD ALU result inputs (from execution_stg2)
        use_csd_result   : in  std_logic;
        csd_result_sign  : in  std_logic;
        csd_result_exp   : in  std_logic_vector(7 downto 0);
        csd_result_mant  : in  std_logic_vector(47 downto 0);  -- For MUL (48-bit) or ADD/SUB (28-bit)
        
        -- ADD Stage 1 outputs -> Stage 2 inputs
        add_A_sign       : in  std_logic;
        add_B_sign       : in  std_logic;
        add_A_exp        : in  std_logic_vector(7 downto 0);
        add_B_exp        : in  std_logic_vector(7 downto 0);
        add_A_mant       : in  std_logic_vector(26 downto 0);
        add_B_mant       : in  std_logic_vector(26 downto 0);
        add_rm           : in  std_logic_vector(2 downto 0);
        add_valid        : in  std_logic;
        
        -- ADD Stage 2 outputs
        add_out_sign     : out std_logic;
        add_out_exp      : out std_logic_vector(7 downto 0);
        add_out_mant     : out std_logic_vector(27 downto 0);
        add_rm_out       : out std_logic_vector(2 downto 0);
        add_valid_out    : out std_logic;
        
        -- SUB Stage 1 outputs -> Stage 2 inputs
        sub_A_sign       : in  std_logic;
        sub_B_sign       : in  std_logic;
        sub_A_exp        : in  std_logic_vector(7 downto 0);
        sub_B_exp        : in  std_logic_vector(7 downto 0);
        sub_A_mant       : in  std_logic_vector(26 downto 0);
        sub_B_mant       : in  std_logic_vector(26 downto 0);
        sub_rm           : in  std_logic_vector(2 downto 0);
        
        -- SUB Stage 2 outputs
        sub_out_sign     : out std_logic;
        sub_out_exp      : out std_logic_vector(7 downto 0);
        sub_out_mant     : out std_logic_vector(27 downto 0);
        sub_rm_out       : out std_logic_vector(2 downto 0);
        
        -- MUL Stage 1 outputs -> Stage 2 inputs
        mul_A_sign       : in  std_logic;
        mul_B_sign       : in  std_logic;
        mul_A_exp        : in  std_logic_vector(7 downto 0);
        mul_B_exp        : in  std_logic_vector(7 downto 0);
        mul_A_frac       : in  std_logic_vector(22 downto 0);  -- Raw fraction for NaN/Inf detection
        mul_B_frac       : in  std_logic_vector(22 downto 0);
        mul_A_mant       : in  std_logic_vector(26 downto 0);
        mul_B_mant       : in  std_logic_vector(26 downto 0);
        mul_rm           : in  std_logic_vector(2 downto 0);
        
        -- MUL Stage 2 outputs
        mul_product      : out std_logic_vector(47 downto 0);
        mul_exp_sum      : out std_logic_vector(7 downto 0);
        mul_sign_out     : out std_logic;
        mul_a_is_nan     : out std_logic;
        mul_b_is_nan     : out std_logic;
        mul_a_is_inf     : out std_logic;
        mul_b_is_inf     : out std_logic;
        mul_a_is_zero    : out std_logic;
        mul_b_is_zero    : out std_logic;
        mul_rm_out       : out std_logic_vector(2 downto 0);
        
        -- DIV Stage 1 outputs -> Stage 2 inputs
        div_x_val        : in  std_logic_vector(31 downto 0);
        div_y_val        : in  std_logic_vector(31 downto 0);
        div_exp          : in  std_logic_vector(7 downto 0);
        div_sign         : in  std_logic;
        div_special      : in  std_logic;
        div_special_result : in  std_logic_vector(31 downto 0);
        div_valid        : in  std_logic;
        div_rm_in       : in std_logic_vector(2 downto 0);
        
        -- DIV Stage 2 outputs
        div_quotient     : out std_logic_vector(31 downto 0);
        div_sticky       : out std_logic;
        div_exp_out      : out std_logic_vector(7 downto 0);
        div_sign_out     : out std_logic;
        div_rm_out       : out std_logic_vector(2 downto 0);
        div_special_out  : out std_logic;
        div_special_result_out : out std_logic_vector(31 downto 0);
        div_valid_out    : out std_logic;
        ---div_s1_valid_out : out std_logic;
        div_busy         : out std_logic
    );
end entity fpu_stage2;

architecture rtl of fpu_stage2 is



begin


     --div_s1_valid_out <= div_valid;  ---- pass through from stage1 to stage2

    --==============================================================================
    -- ADDER STAGE 2 INSTANTIATION
    --==============================================================================
    add_stage2_inst : entity work.ieee754_adder_stage2
    port map (
        clk                => clk,
        reset              => reset,
        stall              => stall,
        --alu_op_in          => ALU_FADD,
        en_fadd            => en_fadd,
        A_sign_in          => add_A_sign,
        B_sign_in          => add_B_sign,
        A_exp_in           => add_A_exp,
        B_exp_in           => add_B_exp,
        A_mant_in          => add_A_mant,
        B_mant_in          => add_B_mant,
        rm_in              => add_rm,
        valid_in          => add_valid,
        use_csd_result     => use_csd_result,
        csd_result_sign    => csd_result_sign,
        csd_result_exp     => csd_result_exp,
        csd_result_mant    => csd_result_mant(27 downto 0),
        result_sign        => add_out_sign,
        result_exp         => add_out_exp,
        valid_out         => add_valid_out,
        result_mant        => add_out_mant,
        rm_out             => add_rm_out
    );
    
    
    --==============================================================================
    -- SUBTRACTOR STAGE 2 INSTANTIATION
    --==============================================================================
    sub_stage2_inst : entity work.ieee754_subtractor_stage2
    port map (
        clk                => clk,
        reset              => reset,
        stall              => stall,
        --alu_op_in          => ALU_FSUB,
        en_fsub            => en_fsub,
        A_sign             => sub_A_sign,
        B_sign             => sub_B_sign,
        A_exp              => sub_A_exp,
        B_exp              => sub_B_exp,
        A_mant             => sub_A_mant,
        B_mant             => sub_B_mant,
        rm_in              => sub_rm,
        use_csd_result     => use_csd_result,
        csd_result_sign    => csd_result_sign,
        csd_result_exp     => csd_result_exp,
        csd_result_mant    => csd_result_mant(27 downto 0),
        out_sign           => sub_out_sign,
        out_exponent       => sub_out_exp,
        out_mantissa       => sub_out_mant,
        rm_out             => sub_rm_out
    );
    
    
    --==============================================================================
    -- MULTIPLIER STAGE 2 INSTANTIATION
    --==============================================================================
    mul_stage2_inst : entity work.ieee754mult_stage2
    port map (
        clk                => clk,
        reset              => reset,
        stall              => stall,
        --alu_op_in          => ALU_FMUL,
        en_fmul            => en_fmul,
        A_sign             => mul_A_sign,
        B_sign             => mul_B_sign,
        A_exp              => mul_A_exp,
        B_exp              => mul_B_exp,
        A_frac             => mul_A_frac,
        B_frac             => mul_B_frac,
        A_mant             => mul_A_mant(23 downto 0),
        B_mant             => mul_B_mant(23 downto 0),
        rm_in              => mul_rm,
        use_csd_result     => use_csd_result,
        csd_result_sign    => csd_result_sign,
        csd_result_exp     => csd_result_exp,
        csd_result_mant    => csd_result_mant,
        product            => mul_product,
        exp_sum            => mul_exp_sum,
        sign_out           => mul_sign_out,
        a_is_nan           => mul_a_is_nan,
        b_is_nan           => mul_b_is_nan,
        a_is_inf           => mul_a_is_inf,
        b_is_inf           => mul_b_is_inf,
        a_is_zero          => mul_a_is_zero,
        b_is_zero          => mul_b_is_zero,
        rm_out             => mul_rm_out
    );
    
    
    --==============================================================================
    -- DIVIDER STAGE 2 INSTANTIATION
    --==============================================================================
    div_stage2_inst : entity work.ieee754_div_stage2
    port map (
        clk                 => clk,
        reset               => reset,
        --alu_op_in          => ALU_FDIV,
        en_fdiv             => en_fdiv,
        x_val_in            => div_x_val,
        y_val_in            => div_y_val,
        result_exp_in       => div_exp,
        result_sign_in      => div_sign,
        special_case_in     => div_special,
        special_result_in   => div_special_result,
        rm_in               => div_rm_in,  
        valid_in            => div_valid,   ---s1_valid_in   
        quotient            => div_quotient,
        sticky              => div_sticky,
        result_exp_out      => div_exp_out,
        result_sign_out     => div_sign_out,
        special_case_out    => div_special_out,
        special_result_out  => div_special_result_out,
        rm_out              => div_rm_out,
        --s1_valid_out        => div_s1_valid_out,  ----s1_valid in just passed here need to latch maybe in execution_stg2  
        valid_out           => div_valid_out,
        busy                => div_busy   ----s2_busy
    );
    
       
    
   
end architecture rtl;
