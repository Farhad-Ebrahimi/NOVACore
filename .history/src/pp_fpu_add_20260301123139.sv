//==============================================================================
// FP ADDER - 3 SEPARATE STAGE MODULES
// To be instantiated in execution_stg1, execution_stg2, execution_stg3
//==============================================================================

//==============================================================================
// STAGE 1: EXTRACTION & ALIGNMENT
//==============================================================================





module ieee754_adder_stage1 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        ex_stall,  
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  rm,
    input  logic        en_fadd,  
    
    output logic        A_sign,
    output logic        B_sign,
    output logic [7:0]  A_exp,
    output logic [7:0]  B_exp,
    output logic [26:0] A_mant,
    output logic [26:0] B_mant,
    output logic [2:0]  rm_out,
    output logic        s1_valid   ////added 
);

    logic s1_A_sign, s1_B_sign;

    logic valid; ///added 
   
    logic [7:0]  s1_A_exp, s1_B_exp;
    logic [26:0] s1_A_mant, s1_B_mant;
    logic [2:0]  s1_rm;

    always_ff @(posedge clk) begin
        if (reset) begin
            s1_A_sign <= 0; s1_B_sign <= 0;
            s1_A_exp  <= 0; s1_B_exp  <= 0;
            s1_A_mant <= 0; s1_B_mant <= 0;
            s1_rm     <= 0;
            //valid <= 0; 
        end else if (!stall && !ex_stall)
      
        begin   //&& en_fadd
            s1_A_sign <= A[31];
            s1_B_sign <= B[31];
            s1_A_exp  <= A[30:23];
            s1_B_exp  <= B[30:23];
            s1_rm     <= rm;
             //valid <= 1; 
            

            // Extend mantissa to 27 bits: [hidden bit][23-bit fraction][3-bit GRS = 000]
            if (A[30:23] == 8'd0)
                s1_A_mant <= {1'b0, A[22:0], 3'b000};  // Denormal
               
            else
                s1_A_mant <= {1'b1, A[22:0], 3'b000};  // Normal    
            
            if (B[30:23] == 8'd0)
                s1_B_mant <= {1'b0, B[22:0], 3'b000};  // Denormal
               
            else
                s1_B_mant <= {1'b1, B[22:0], 3'b000};  // Normal
               
          

            
            
        end
        //else begin
        //    valid <= 0;
        //end
    end

    assign A_sign = s1_A_sign;
    assign B_sign = s1_B_sign;
    assign A_exp  = s1_A_exp;
    assign B_exp  = s1_B_exp;
    assign A_mant = s1_A_mant;
    assign B_mant = s1_B_mant;
    assign rm_out = s1_rm;
    //assign s1_valid = valid;
endmodule

//==============================================================================
// STAGE 2: MANTISSA COMPUTATION (takes CSD result from execution_stg2)
//==============================================================================
module ieee754_adder_stage2 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
     input  logic        ex_stall,  
    input  logic        en_fadd, 
    // From Stage 1
    input  logic        A_sign_in,
    input  logic        B_sign_in,
    input  logic [7:0]  A_exp_in,
    input  logic [7:0]  B_exp_in,
    input  logic [26:0] A_mant_in,
    input  logic [26:0] B_mant_in,
    input  logic [2:0]  rm_in,

    input  logic        valid_in,  //s1_valid_in
    
    // CSD mode control
    input  logic        use_csd_result,  // When '1', use CSD ALU result; when '0', use binary
    
    // CSD result from execution_stg2 CSD ALU
    input  logic        csd_result_sign,
    input  logic [7:0]  csd_result_exp,
    input  logic [27:0] csd_result_mant,
    
    // To Stage 3
    output logic        result_sign,
    output logic [7:0]  result_exp,
    output logic [27:0] result_mant,
    output logic        valid_out,  //s2_valid_out
    output logic [2:0]  rm_out
);

    logic        s2_out_sign;
    logic [7:0]  s2_out_exponent;
    logic [27:0] s2_out_mantissa;
    logic [2:0]  s2_rm;

    // Computation variables for Stage 2
    logic [7:0]  s2_diff;
    logic [26:0] s2_shifted_mant;
    logic [27:0] s2_mant_result;
    logic [7:0]  s2_exp_result;
    logic        s2_sign_result;
    logic        s2_sticky_or;

    // Special case detection
    logic a_is_nan, b_is_nan, a_is_inf, b_is_inf;
    logic a_is_zero, b_is_zero;
    logic both_zero, cancel_to_zero;
    
    assign a_is_nan = (A_exp_in == 8'hFF) && (A_mant_in[25:3] != 23'd0);
    assign b_is_nan = (B_exp_in == 8'hFF) && (B_mant_in[25:3] != 23'd0);
    assign a_is_inf = (A_exp_in == 8'hFF) && (A_mant_in[25:3] == 23'd0);
    assign b_is_inf = (B_exp_in == 8'hFF) && (B_mant_in[25:3] == 23'd0);
    
    // Zero detection: exp=0 and mantissa=0 (or just implicit bit not set for subnormal)
    assign a_is_zero = (A_exp_in == 8'h00) && (A_mant_in[26] == 1'b0);
    assign b_is_zero = (B_exp_in == 8'h00) && (B_mant_in[26] == 1'b0);
    
    // Special case: 0 + 0 = 0
    assign both_zero = a_is_zero && b_is_zero;
    
    // Special case: x + (-x) = 0 (same exp, same mantissa, opposite signs)
    assign cancel_to_zero = (A_sign_in != B_sign_in) && 
                            (A_exp_in == B_exp_in) && 
                            (A_mant_in == B_mant_in) &&
                            !a_is_nan && !b_is_nan && !a_is_inf && !b_is_inf;

    always_ff @(posedge clk) begin
        if (reset) begin
            s2_out_sign     <= 1'b0;
            s2_out_exponent <= 8'd0;
            s2_out_mantissa <= 28'd0;
            s2_rm           <= 3'b000;
        end else if (!stall && !ex_stall) begin  //&& en_fadd
            //if (valid_in) begin
            s2_rm <= rm_in;

            // Handle NaN / Infinity cases
            if (a_is_nan || b_is_nan) begin
                s2_out_sign     <= 1'b0;
                s2_out_exponent <= 8'hFF;
                s2_out_mantissa <= 28'h2000000;  // Canonical NaN
            end else if (a_is_inf && b_is_inf && (A_sign_in != B_sign_in)) begin
                // INF + (-INF) = NaN
                s2_out_sign     <= 1'b0;
                s2_out_exponent <= 8'hFF;
                s2_out_mantissa <= 28'h2000000;
            end else begin
                // Normal addition/subtraction path (same logic as fpu.sv)
                if (A_exp_in > B_exp_in) begin
                    s2_diff = A_exp_in - B_exp_in;
                    
                    if (s2_diff >= 27) begin
                        s2_shifted_mant = 27'd0;
                        s2_sticky_or = |B_mant_in;
                    end else begin
                        s2_shifted_mant = B_mant_in >> s2_diff;
                        if (s2_diff > 0)
                            s2_sticky_or = |(B_mant_in & ((27'd1 << s2_diff) - 27'd1));
                        else
                            s2_sticky_or = 1'b0;
                        if (s2_sticky_or)
                            s2_shifted_mant[0] = 1'b1;
                    end
                    
                    s2_exp_result = A_exp_in;
                    if (A_sign_in == B_sign_in)
                        s2_mant_result = {1'b0, A_mant_in} + {1'b0, s2_shifted_mant};
                    else if (A_mant_in >= s2_shifted_mant)
                        s2_mant_result = {1'b0, A_mant_in} - {1'b0, s2_shifted_mant};
                    else
                        s2_mant_result = {1'b0, s2_shifted_mant} - {1'b0, A_mant_in};
                    s2_sign_result = (A_mant_in >= s2_shifted_mant) ? A_sign_in : B_sign_in;

                end else if (B_exp_in > A_exp_in) begin
                    s2_diff = B_exp_in - A_exp_in;
                    
                    if (s2_diff >= 27) begin
                        s2_shifted_mant = 27'd0;
                        s2_sticky_or = |A_mant_in;
                    end else begin
                        s2_shifted_mant = A_mant_in >> s2_diff;
                        if (s2_diff > 0)
                            s2_sticky_or = |(A_mant_in & ((27'd1 << s2_diff) - 27'd1));
                        else
                            s2_sticky_or = 1'b0;
                        if (s2_sticky_or)
                            s2_shifted_mant[0] = 1'b1;
                    end
                    
                    s2_exp_result = B_exp_in;
                    if (A_sign_in == B_sign_in)
                        s2_mant_result = {1'b0, B_mant_in} + {1'b0, s2_shifted_mant};
                    else if (B_mant_in >= s2_shifted_mant)
                        s2_mant_result = {1'b0, B_mant_in} - {1'b0, s2_shifted_mant};
                    else
                        s2_mant_result = {1'b0, s2_shifted_mant} - {1'b0, B_mant_in};
                    s2_sign_result = (B_mant_in >= s2_shifted_mant) ? B_sign_in : A_sign_in;

                end else begin
                    // Exponents equal
                    s2_exp_result = A_exp_in;
                    if (A_sign_in == B_sign_in)
                        s2_mant_result = {1'b0, A_mant_in} + {1'b0, B_mant_in};
                    else if (A_mant_in >= B_mant_in)
                        s2_mant_result = {1'b0, A_mant_in} - {1'b0, B_mant_in};
                    else
                        s2_mant_result = {1'b0, B_mant_in} - {1'b0, A_mant_in};
                    s2_sign_result = (A_mant_in >= B_mant_in) ? A_sign_in : B_sign_in;
                end

                // Handle zero result
                if (s2_mant_result == 0) begin
                    s2_exp_result = 8'd0;
                    s2_sign_result = 1'b0;
                end

                s2_out_sign     <= s2_sign_result;
                s2_out_exponent <= s2_exp_result;
                s2_out_mantissa <= s2_mant_result;
            end
            
            // Priority hierarchy: NaN > INF special cases > Zero special cases > CSD result > binary result
            // Handle zero special cases first
            if (both_zero || cancel_to_zero) begin
                // 0+0=0 or x+(-x)=0: result is positive zero
                s2_out_sign     <= 1'b0;
                s2_out_exponent <= 8'd0;
                s2_out_mantissa <= 28'd0;

                //dead code part not being used kept for future modifications 
            end else if (!(a_is_nan || b_is_nan) && 
                !(a_is_inf && b_is_inf && (A_sign_in != B_sign_in)) &&
                use_csd_result) begin
                // Compute sign internally for CSD mode (avoids timing issues)
                // For same-sign operands: result sign = operand signs
                // For different-sign operands: result sign = sign of larger magnitude
                if (A_sign_in == B_sign_in) begin
                    s2_out_sign <= A_sign_in;
                end else begin
                    // Different signs: use sign of larger magnitude operand
                    if (A_exp_in > B_exp_in)
                        s2_out_sign <= A_sign_in;
                    else if (B_exp_in > A_exp_in)
                        s2_out_sign <= B_sign_in;
                    else begin
                        // Equal exponents: compare mantissas
                        if (A_mant_in >= B_mant_in)
                            s2_out_sign <= A_sign_in;
                        else
                            s2_out_sign <= B_sign_in;
                    end
                end
                s2_out_exponent <= csd_result_exp;
                s2_out_mantissa <= csd_result_mant;
            end
            end
       //end
    end

    assign result_sign = s2_out_sign;
    assign result_exp  = s2_out_exponent;
    assign result_mant = s2_out_mantissa;
    assign rm_out      = s2_rm;
    assign valid_out   = valid_in;  // Pass through validity from Stage 1

endmodule

//==============================================================================
// STAGE 3: NORMALIZATION & ROUNDING
//==============================================================================
module ieee754_adder_stage3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
        input  logic        ex_stall,
    input  logic        en_fadd, 
    input  logic        valid_in,  //s2_valid_in
    input  logic        s1_valid_out,
    
    // From Stage 2
    input  logic        sign_in,
    input  logic [7:0]  exp_in,
    input  logic [27:0] mant_in,
    input  logic [2:0]  rm_in,
    
    // Final result
    output logic [31:0] result,
    output logic [4:0]  flags,
    output logic        done   ////added
);

    logic [31:0] s3_result;
    logic [4:0]  s3_flags;
    logic [2:0]  grs_bits;

    always_ff @(posedge clk) begin
        if (reset) begin
            s3_result <= 32'd0;
            s3_flags  <= 5'b00000;
            grs_bits  <= 3'b000;
            done <= 0;
        end 
        else if (!stall ) begin  //
            //done <= 0; 
           // if (valid_in) begin
                logic [7:0]  norm_exp;
                logic [27:0] norm_mant;
                logic [24:0] mant_rounded_wide;
                int  lz;
                logic [31:0] result_temp;
                logic guard, round, sticky;

                norm_exp  = exp_in;
                norm_mant = mant_in;
                result_temp = 32'd0;
                lz = 0;
                //done <= 0; 

                // Capture GRS for flags
                grs_bits <= mant_in[2:0];

                if (norm_exp == 8'hFF) begin
                    // Infinity / NaN: pass through
                    result_temp = {sign_in, norm_exp, norm_mant[25:3]};
                end else if (norm_mant == 28'd0) begin
                    result_temp = 32'd0;
                end else 
                begin    
                    // Normalize: leading 1 must be at bit 26 (27-bit mantissa format with bit 27 for overflow)
                    if (norm_mant[27]) begin
                        // Overflow: shift right and increment exponent
                        norm_exp  = norm_exp + 1;
                        norm_mant = norm_mant >> 1;
                    end else if (!norm_mant[26]) 
                    begin  
                        // Leading zeros - count leading zeros starting from bit 26
                        lz = 0;
                        for (int i = 26; i >= 0; i--) begin
                            if (norm_mant[i]) break;
                            lz = lz + 1;
                        end
                        // lz is now the count of leading zeros before bit 26
                        if (lz > 0) 
                        begin
                            if (norm_exp > lz) begin
                                norm_exp  = norm_exp - lz;
                                norm_mant = norm_mant << lz;
                            end else begin
                                // Underflow: shift as much as possible
                                norm_mant = norm_mant << (norm_exp - 1);
                                norm_exp  = 0;
                            end
                        end
                    end
                    // else: bit 26 is already set, no normalization needed

                    // Extract GRS bits
                    guard  = norm_mant[2];
                    round  = norm_mant[1];
                    sticky = norm_mant[0];

                    // Round
                    case (rm_in)
                        3'b000: mant_rounded_wide = {1'b0, norm_mant[26:3]} + (guard && (round || sticky || norm_mant[3]) ? 25'd1 : 25'd0);
                        3'b001: mant_rounded_wide = {1'b0, norm_mant[26:3]};
                        3'b010: mant_rounded_wide = {1'b0, norm_mant[26:3]} + (sign_in && (guard || round || sticky) ? 25'd1 : 25'd0);
                        3'b011: mant_rounded_wide = {1'b0, norm_mant[26:3]} + (!sign_in && (guard || round || sticky) ? 25'd1 : 25'd0);
                        3'b100: mant_rounded_wide = {1'b0, norm_mant[26:3]} + (guard ? 25'd1 : 25'd0);
                        default: mant_rounded_wide = {1'b0, norm_mant[26:3]} + (guard && (round || sticky || norm_mant[3]) ? 25'd1 : 25'd0);
                    endcase

                    // Handle rounding overflow
                    if (mant_rounded_wide[24]) begin
                        mant_rounded_wide = mant_rounded_wide >> 1;
                        norm_exp = norm_exp + 1;
                    end

                    // Check overflow/underflow
                    if (norm_exp >= 8'hFF)
                        result_temp = {sign_in, 8'hFF, 23'd0};
                    else if (norm_exp == 8'd0)
                        result_temp = {sign_in, 8'd0, 23'd0};
                    else
                        result_temp = {sign_in, norm_exp, mant_rounded_wide[22:0]};

                end

                s3_result <= result_temp;
                //
                


                // Flags
                s3_flags[4] <= (norm_exp == 8'hFF) && (norm_mant[25:3] != 23'd0); // NV
                s3_flags[3] <= 1'b0; // DZ (not applicable)
                s3_flags[2] <= (result_temp[30:23] == 8'hFF) && (result_temp[22:0] == 23'd0); // OF
                s3_flags[1] <= (result_temp[30:23] == 8'd0) && (result_temp[22:0] != 23'd0); // UF
                s3_flags[0] <= |grs_bits; // NX


           // end 

           
         end
        
     end

    assign result = s3_result;
  
    assign flags = s3_flags;

endmodule