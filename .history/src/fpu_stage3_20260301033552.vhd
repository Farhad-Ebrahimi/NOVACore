--==============================================================================
-- FPU STAGE 3 WRAPPER (VHDL)
-- Parallel FADD, FSUB, FMUL, FDIV Stage 3 operations
-- Final result muxing based on funct7
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

entity fpu_stage3 is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        stall            : in  std_logic;
        start            : in  std_logic;
        en_fadd : in std_logic;
        en_fsub : in std_logic;
        en_fmul : in std_logic;
        en_fdiv : in std_logic;


        alu_op_in            : in  alu_operation;
        
        -- Operation selector (from pipeline register)
        funct7           : in  std_logic_vector(6 downto 0);
        
        -- ADD Stage 2 outputs -> Stage 3 inputs
        add_sign         : in  std_logic;
        add_exp          : in  std_logic_vector(7 downto 0);
        add_mant         : in  std_logic_vector(27 downto 0);
        add_rm           : in  std_logic_vector(2 downto 0);
        add_s1_valid_out : in  std_logic;  ---- coming from stage2
        add_valid        : in  std_logic;
        
        -- SUB Stage 2 outputs -> Stage 3 inputs
        sub_sign         : in  std_logic;
        sub_exp          : in  std_logic_vector(7 downto 0);
        sub_mant         : in  std_logic_vector(27 downto 0);
        sub_rm           : in  std_logic_vector(2 downto 0);
        
        -- MUL Stage 2 outputs -> Stage 3 inputs
        mul_product      : in  std_logic_vector(47 downto 0);
        mul_exp_sum      : in  std_logic_vector(7 downto 0);
        mul_sign         : in  std_logic;
        mul_a_is_nan     : in  std_logic;
        mul_b_is_nan     : in  std_logic;
        mul_a_is_inf     : in  std_logic;
        mul_b_is_inf     : in  std_logic;
        mul_a_is_zero    : in  std_logic;
        mul_b_is_zero    : in  std_logic;
        mul_rm           : in  std_logic_vector(2 downto 0);
        
        -- DIV Stage 2 outputs -> Stage 3 inputs
        div_quotient     : in  std_logic_vector(31 downto 0);
        div_sticky       : in  std_logic;
        div_exp          : in  std_logic_vector(7 downto 0);
        div_sign         : in  std_logic;
        div_special      : in  std_logic;
        div_special_result : in  std_logic_vector(31 downto 0);
        div_valid        : in  std_logic;
        div_rm           : in  std_logic_vector(2 downto 0);
        div_busy        : in  std_logic;
        div_s1_valid_out : in  std_logic;  ---- coming from stage2
        
        -- Final muxed output
        result_out       : out std_logic_vector(31 downto 0);
        flags_out        : out std_logic_vector(4 downto 0);
        s3_busy          : out std_logic;
        div_done         : out std_logic;
        add_done         : out std_logic



    );
end entity fpu_stage3;

architecture rtl of fpu_stage3 is



        signal alu_op            :  alu_operation;
        
        -- Operation selector (from pipeline register)
        signal funct7_in           :  std_logic_vector(6 downto 0);
        
        -- ADD Stage 2 outputs -> Stage 3 inputs
        signal add_sign_in         :  std_logic;
        signal add_exp_in          :  std_logic_vector(7 downto 0);
        signal add_mant_in         :  std_logic_vector(27 downto 0);
        signal add_rm_in           :  std_logic_vector(2 downto 0);
        signal add_s1_valid_out_in :  std_logic;  ---- coming from stage2
        signal add_valid_in        :  std_logic;
        
        ---signal -- SUB Stage 2 outputs -> Stage 3 inputs
        signal sub_sign_in         :  std_logic;
        signal sub_exp_in          :  std_logic_vector(7 downto 0);
        signal sub_mant_in         :  std_logic_vector(27 downto 0);
        signal sub_rm_in           :  std_logic_vector(2 downto 0);
        
        -- MUL Stage 2 outputs -> Stage 3 inputs
        signal mul_product_in      :  std_logic_vector(47 downto 0);
        signal mul_exp_sum_in      :  std_logic_vector(7 downto 0);
        signal mul_sign_in         :  std_logic;
        signal mul_a_is_nan_in     :  std_logic;
        signal mul_b_is_nan_in     :  std_logic;
        signal mul_a_is_inf_in     :  std_logic;
        signal mul_b_is_inf_in     :  std_logic;
        signal mul_a_is_zero_in    :  std_logic;
        signal mul_b_is_zero_in    :  std_logic;
        signal mul_rm_in           :  std_logic_vector(2 downto 0);
        
         -- DIV Stage 2 outputs -> Stage 3 inputs
        signal div_quotient_in     :  std_logic_vector(31 downto 0);
        signal div_sticky_in       :  std_logic;
        signal div_exp_in          :  std_logic_vector(7 downto 0);
        signal div_sign_in         :  std_logic;
        signal div_special_in      :  std_logic;
        signal div_special_result_in :  std_logic_vector(31 downto 0);
        signal div_valid_in        :  std_logic;
        signal div_rm_in           :  std_logic_vector(2 downto 0);
        signal div_busy_in        :  std_logic;
        signal div_s1_valid_out_in :  std_logic;  ---- coming from stage2

    
    -- Internal signals for each operation
   signal add_result_int        : std_logic_vector(31 downto 0);
    signal add_flags_int         : std_logic_vector(4 downto 0);
   -- 
    signal sub_result_int        : std_logic_vector(31 downto 0);
   signal sub_flags_int         : std_logic_vector(4 downto 0);
   -- 
   signal mul_result_int        : std_logic_vector(31 downto 0);
   signal mul_flags_int         : std_logic_vector(4 downto 0);
   -- 
     signal div_result_int        : std_logic_vector(31 downto 0);
   signal div_flags_int         : std_logic_vector(4 downto 0);
   signal div_done_int          : std_logic;
   -- 
   

begin



     register_inputs : process(clk)
     begin
        if rising_edge(clk) then
           
                 add_sign_in         <= add_sign;
                 add_exp_in          <= add_exp;
                 add_mant_in         <= add_mant;
                 add_rm_in           <= add_rm;
                 add_s1_valid_out_in <= add_s1_valid_out;
                 add_valid_in        <= add_valid;
                 
                 sub_sign_in         <= sub_sign;
                 sub_exp_in          <= sub_exp;
                 sub_mant_in         <= sub_mant;
                 sub_rm_in           <= sub_rm;
                 
                 mul_product_in      <= mul_product;
                 mul_exp_sum_in      <= mul_exp_sum;
                 mul_sign_in         <= mul_sign;
                 mul_a_is_nan_in     <= mul_a_is_nan;
                 mul_b_is_nan_in     <= mul_b_is_nan;
                 mul_a_is_inf_in     <= mul_a_is_inf;
                 mul_b_is_inf_in     <= mul_b_is_inf;
                 mul_a_is_zero_in    <= mul_a_is_zero;
                 mul_b_is_zero_in    <= mul_b_is_zero;
                 mul_rm_in           <= mul_rm;

                 funct)7_in           <= funct7;


                    div_quotient_in     <= div_quotient;
                    div_sticky_in       <= div_sticky;
                    div_exp_in          <= div_exp;
                    div_sign_in         <= div_sign;


                    div_special_in      <= div_special;
                    div_special_result_in <= div_special_result;
                    div_valid_in        <= div_valid;
                    div_rm_in           <= div_rm;
                    div_busy_in         <= div_busy;
                    div_s1_valid_out_in <= div_s1_valid_out;
                    alu_op <= alu_op_in;

            
        end if;
        end process register_inputs;


                 


    ----------------------------------------------------------------------------
    -- Instantiate FADD Stage 3
    ----------------------------------------------------------------------------
    add_stage3 : entity work.ieee754_adder_stage3
        port map (
            clk      => clk,
            reset    => reset,
            stall    => stall,
            sign_in  => add_sign_in,
            valid_in        => add_valid_in,   --s2_valid_in
            s1_valid_out    => add_s1_valid_out_in,
            exp_in   => add_exp_in,
            mant_in  => add_mant_in,
            rm_in    => add_rm_in,
            result   => add_result_int,
            flags    => add_flags_int,
            done   => add_done,
            en_fadd  => en_fadd
            
        );

    ----------------------------------------------------------------------------
    -- Instantiate FSUB Stage 3
    ----------------------------------------------------------------------------
    sub_stage3 : entity work.ieee754_subtractor_stage3
        port map (
            clk           => clk,
            reset         => reset,
            stall         => stall,
            in_sign       => sub_sign_in,
            in_exponent   => sub_exp_in,
            in_mantissa   => sub_mant_in,
            rm            => sub_rm_in,
            result        => sub_result_int,
            flags         => sub_flags_int,
            en_fsub       => en_fsub
        );

    ----------------------------------------------------------------------------
    -- Instantiate FMUL Stage 3
    ----------------------------------------------------------------------------
    mul_stage3 : entity work.ieee754mult_stage3
        port map (
            clk       => clk,
            reset     => reset,
            stall     => stall,
            product   => mul_product_in,
            exp_sum   => mul_exp_sum_in,
            sign      => mul_sign_in,
            a_is_nan  => mul_a_is_nan_in,
            b_is_nan  => mul_b_is_nan_in,
            a_is_inf  => mul_a_is_inf_in,
            b_is_inf  => mul_b_is_inf_in,
            a_is_zero => mul_a_is_zero_in,
            b_is_zero => mul_b_is_zero_in,
            rm        => mul_rm_in,
            result    => mul_result_int,
            flags     => mul_flags_int,
            en_fmul   => en_fmul
        );

    ----------------------------------------------------------------------------
    -- Instantiate FDIV Stage 3
    -- Note: DIV Stage 3 has no stall signal and handles its own valid/done logic
    ----------------------------------------------------------------------------
    div_stage3 : entity work.ieee754_div_stage3
        port map (
            clk             => clk,
            reset           => reset,
            quotient_in     => div_quotient_in,
            sticky_in       => div_sticky_in,
            start          => start,
            result_exp_in   => div_exp_in,
            result_sign_in  => div_sign_in,
            special_case_in => div_special_in,
            special_result_in => div_special_result_in,
            rm_in           => div_rm_in,
            busy_in         => div_busy_in,   --s2_busy_in
            valid_in        => div_valid_in,   --s2_valid_in
            s1_valid_out    => div_s1_valid_out_in,      --in signal
            result          => div_result_int,
            flags           => div_flags_int,
            s3_busy       => s3_busy,   
            done            => div_done_int,
            en_fdiv         => en_fdiv
        );




      div_done   <= div_done_int;

process (alu_op,add_result_int, add_flags_int, sub_result_int, sub_flags_int,
        mul_result_int, mul_flags_int, div_result_int, div_flags_int, div_done_int)
 begin
   case alu_op is
        when ALU_FADD =>
            result_out <= add_result_int;
            flags_out  <= add_flags_int;
            --div_done   <= '1';
        when ALU_FSUB=>
            result_out <= sub_result_int;
            flags_out  <= sub_flags_int;
            --div_done   <= '1';
        when ALU_FMUL =>
            result_out <= mul_result_int;
            flags_out  <= mul_flags_int;
            --div_done   <= '1';
        when ALU_FDIV  =>
              --if div_done_int = '1' then
                  result_out <= div_result_int;
                  flags_out  <= div_flags_int;
             --end if;
            --div_done   <= div_done_int;
        when others =>
            result_out <= (others => '0');
            flags_out  <= (others => '0');
            --div_done   <= '1';  
    end case;
 end process;
--
--
--



    

    
--process(funct7, add_result_int, add_flags_int, sub_result_int, sub_flags_int,
--        mul_result_int, mul_flags_int, div_result_int, div_flags_int, div_done_int)
--begin
--    case funct7 is
--        when "0000000" =>  -- FADD
--            result_out <= add_result_int;
--            flags_out  <= add_flags_int;
--            div_done   <= '1';
--        when "0000100" =>  -- FSUB
--            result_out <= sub_result_int;
--            flags_out  <= sub_flags_int;
--            div_done   <= '1';
--        when "0001000" =>  -- FMUL
--            result_out <= mul_result_int;
--            flags_out  <= mul_flags_int;
--            div_done   <= '1';
--        when "0001100" =>  -- FDIV
--            result_out <= div_result_int;
--            flags_out  <= div_flags_int;
--            div_done   <= div_done_int;
--        when others =>
--            result_out <= (others => '0');
--            flags_out  <= (others => '0');
--            div_done   <= '1';
--    end case;
--end process;

end architecture rtl;