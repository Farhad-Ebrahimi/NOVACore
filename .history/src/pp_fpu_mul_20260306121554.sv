//==============================================================================
// IEEE754 MULTIPLIER - STAGE 1
// Extracts sign, exponent, and 24-bit mantissa
//==============================================================================
module ieee754mult_stage1 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        en_fmul,
     input  logic        ex_stall,  
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  rm,
    output logic        A_sign,
    output logic        B_sign,
    output logic [7:0]  A_exp,
    output logic [7:0]  B_exp,
    output logic [22:0] A_frac,
    output logic [22:0] B_frac,
    output logic [23:0] A_mant,
    output logic [23:0] B_mant,
    output logic [2:0]  rm_out
);

always_comb begin
    A_sign = A[31];
    B_sign = B[31];
    A_exp  = A[30:23];
    B_exp  = B[30:23];
    A_frac = A[22:0];
    B_frac = B[22:0];
    // Handle denormals: implicit 0 if exp=0, else implicit 1
    A_mant = (A[30:23] == 8'd0) ? {1'b0, A[22:0]} : {1'b1, A[22:0]};
    B_mant = (B[30:23] == 8'd0) ? {1'b0, B[22:0]} : {1'b1, B[22:0]};
    rm_out = rm;
end

// ...existing code...
//endmodule

//==============================================================================
// IEEE754 MULTIPLIER - STAGE 2
// Special case detection + multiply (accepts CSD result or internal binary)
//==============================================================================
module ieee754mult_stage2 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        ex_stall,
    input  logic        en_fmul,
    input  logic        A_sign,
    input  logic        B_sign,
    input  logic [7:0]  A_exp,
    input  logic [7:0]  B_exp,
    input  logic [22:0] A_frac,
    input  logic [22:0] B_frac,
    input  logic [23:0] A_mant,
    input  logic [23:0] B_mant,
    input  logic [2:0]  rm_in,
    input  logic        use_csd_result,
    input  logic        csd_result_sign,
    input  logic [7:0]  csd_result_exp,
    input  logic [47:0] csd_result_mant,
    output logic [47:0] product,
    output logic [7:0]  exp_sum,
    output logic        sign_out,
    output logic        a_is_nan,
    output logic        b_is_nan,
    output logic        a_is_inf,
    output logic        b_is_inf,
    output logic        a_is_zero,
    output logic        b_is_zero,
    output logic [2:0]  rm_out
);

always_comb begin
    // Detect special cases
    a_is_nan  = (A_exp == 8'hFF) && (A_frac != 0);
    b_is_nan  = (B_exp == 8'hFF) && (B_frac != 0);
    a_is_inf  = (A_exp == 8'hFF) && (A_frac == 0);
    b_is_inf  = (B_exp == 8'hFF) && (B_frac == 0);
    a_is_zero = (A_exp == 8'd0) && (A_mant == 24'd0);
    b_is_zero = (B_exp == 8'd0) && (B_mant == 24'd0);

    if (use_csd_result) begin
        product = csd_result_mant;
        exp_sum = csd_result_exp;
        sign_out = csd_result_sign;
    end else begin
        product = A_mant * B_mant;
        exp_sum = A_exp + B_exp - 127;
        sign_out = A_sign ^ B_sign;
    end
    rm_out = rm_in;
end

// ...existing code...

//==============================================================================
// IEEE754 MULTIPLIER - STAGE 3
// Special case handling + normalize + pack
//==============================================================================
module ieee754mult_stage3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        ex_stall,
    input  logic        en_fmul,
    always_comb begin
        logic [7:0]  exp_local;
        logic [47:0] prod_local;
        logic        sign_local;
        logic [4:0]  temp_flags;
        logic [24:0] mant_rounded_wide;
        logic [22:0] mant_final;
        logic guard, round, sticky;

        exp_local  = exp_sum;
        prod_local = product;
        sign_local = sign;
        temp_flags = 5'b0;

        // Special case handling
        if (a_is_nan || b_is_nan) begin
            result = 32'h7fc00000;
            temp_flags[4] = 1;
        end else if ((a_is_inf && b_is_zero) || (a_is_zero && b_is_inf)) begin
            result = 32'h7fc00000;
            temp_flags[4] = 1;
        end else if (a_is_inf || b_is_inf) begin
            result = {sign_local, 8'hFF, 23'd0};
        end else if (a_is_zero || b_is_zero) begin
            result = {sign_local, 8'd0, 23'd0};
        end else begin
            // Normal multiplication with rounding
            if (prod_local[47]) begin
                // Product ≥ 2.0
                guard  = prod_local[23];
                round  = prod_local[22];
                sticky = |prod_local[21:0];
                exp_local = exp_local + 1;
            
                case (rm)
                    3'b000: if (guard && (round || sticky || prod_local[24])) mant_rounded_wide = {1'b0, prod_local[46:24]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[46:24]};
                    3'b001: mant_rounded_wide = {1'b0, prod_local[46:24]};
                    3'b010: if (sign_local && (guard || round || sticky)) mant_rounded_wide = {1'b0, prod_local[46:24]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[46:24]};
                    3'b011: if (!sign_local && (guard || round || sticky)) mant_rounded_wide = {1'b0, prod_local[46:24]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[46:24]};
                    3'b100: if (guard) mant_rounded_wide = {1'b0, prod_local[46:24]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[46:24]};
                    default: if (guard && (round || sticky || prod_local[24])) mant_rounded_wide = {1'b0, prod_local[46:24]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[46:24]};
                endcase
            
                if (mant_rounded_wide[24]) begin
                    mant_final = 23'd0;
                    exp_local = exp_local + 1;
                end else begin
                    mant_final = mant_rounded_wide[22:0];
                end
            
            end else begin
                // Product in [1.0, 2.0)
                guard  = prod_local[22];
                round  = prod_local[21];
                sticky = |prod_local[20:0];
            
                case (rm)
                    3'b000: if (guard && (round || sticky || prod_local[23])) mant_rounded_wide = {1'b0, prod_local[45:23]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[45:23]};
                    3'b001: mant_rounded_wide = {1'b0, prod_local[45:23]};
                    3'b010: if (sign_local && (guard || round || sticky)) mant_rounded_wide = {1'b0, prod_local[45:23]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[45:23]};
                    3'b011: if (!sign_local && (guard || round || sticky)) mant_rounded_wide = {1'b0, prod_local[45:23]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[45:23]};
                    3'b100: if (guard) mant_rounded_wide = {1'b0, prod_local[45:23]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[45:23]};
                    default: if (guard && (round || sticky || prod_local[23])) mant_rounded_wide = {1'b0, prod_local[45:23]} + 25'd1; else mant_rounded_wide = {1'b0, prod_local[45:23]};
                endcase
            
                if (mant_rounded_wide[24]) begin
                    mant_final = 23'd0;
                    exp_local = exp_local + 1;
                end else begin
                    mant_final = mant_rounded_wide[22:0];
                end
            end

            // Check overflow/underflow
            if (exp_local >= 8'hFF) begin
                result = {sign_local, 8'hFF, 23'd0};
                temp_flags[2] = 1;
                temp_flags[0] = 1;
            end else if (exp_local <= 0) begin
                result = {sign_local, 8'd0, 23'd0};
                temp_flags[1] = 1;
                temp_flags[0] = 1;
            end else begin
                result = {sign_local, exp_local, mant_final};
                if (guard || round || sticky) temp_flags[0] = 1;
            end
        end

        flags = temp_flags;
    end
                if (guard || round || sticky) temp_flags[0] = 1;
            end
        end

        flags = temp_flags;
end

// ...existing code...

