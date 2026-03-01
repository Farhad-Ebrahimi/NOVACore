//==============================================================================
// IEEE754 SUBTRACTOR - STAGE 1
// Extracts sign, exponent, and 27-bit mantissa (24 + 3 GRS bits)
//==============================================================================
module ieee754_subtractor_stage1 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
     input  logic        ex_stall,  
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  rm,
    input  logic        en_fsub,  
    output logic        A_sign,
    output logic        B_sign,
    output logic [7:0]  A_exp,
    output logic [7:0]  B_exp,
    output logic [26:0] A_mant,
    output logic [26:0] B_mant,
    output logic [2:0]  rm_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        A_sign <= 0; B_sign <= 0;
        A_exp  <= 0; B_exp  <= 0;
        A_mant <= 0; B_mant <= 0;
        rm_out <= 0;
    end else if (!stall && !ex_stall) begin ///&& en_fsub
        A_sign <= A[31];
        B_sign <= ~B[31];  // invert B's sign → subtraction = A + (-B)
        A_exp  <= A[30:23];
        B_exp  <= B[30:23];
        rm_out <= rm;

        // Extend mantissa to 27 bits: [hidden bit][23-bit fraction][3-bit GRS = 000]
        A_mant <= (A[30:23] == 8'd0) ? {1'b0, A[22:0], 3'b000} : {1'b1, A[22:0], 3'b000};
        B_mant <= (B[30:23] == 8'd0) ? {1'b0, B[22:0], 3'b000} : {1'b1, B[22:0], 3'b000};
    end
end

endmodule

//endmodule

//==============================================================================
// IEEE754 SUBTRACTOR - STAGE 2
// Accepts CSD result from execution_stg2, handles special cases
//==============================================================================
module ieee754_subtractor_stage2 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
     input  logic        ex_stall,  
    input  logic        en_fsub,
    input  logic        A_sign,
    input  logic        B_sign,
    input  logic [7:0]  A_exp,
    input  logic [7:0]  B_exp,
    input  logic [26:0] A_mant,
    input  logic [26:0] B_mant,
    input  logic [2:0]  rm_in,
    input  logic        use_csd_result,
    input  logic        csd_result_sign,
    input  logic [7:0]  csd_result_exp,
    input  logic [27:0] csd_result_mant,
    output logic        out_sign,
    output logic [7:0]  out_exponent,
    output logic [27:0] out_mantissa,
    output logic [2:0]  rm_out
);

// Special case detection
logic a_is_nan, b_is_nan, a_is_inf, b_is_inf;
assign a_is_nan = (A_exp == 8'hFF) && (A_mant[25:3] != 23'd0);
assign b_is_nan = (B_exp == 8'hFF) && (B_mant[25:3] != 23'd0);
assign a_is_inf = (A_exp == 8'hFF) && (A_mant[25:3] == 23'd0);
assign b_is_inf = (B_exp == 8'hFF) && (B_mant[25:3] == 23'd0);

always_ff @(posedge clk) begin
    if (reset) begin
        out_sign     <= 1'b0;
        out_exponent <= 8'd0;
        out_mantissa <= 28'd0;
        rm_out       <= 3'b000;
    end else if (!stall && !ex_stall) begin ///&& en_fsub
        logic [7:0]  diff;
        logic [26:0] shifted_mant;
        logic [27:0] mant_result;
        logic [7:0]  exp_result;
        logic        sign_result;
        logic        sticky_or;

        rm_out <= rm_in;

        // Handle NaN / Infinity / Finite separately
        if (a_is_nan || b_is_nan) begin
            exp_result  = 8'hFF;
            mant_result = 28'h2000000;
            sign_result = 1'b0;

        end else if (a_is_inf || b_is_inf) begin
            if (a_is_inf && b_is_inf && (A_sign != B_sign)) begin
                // INF - INF with same original sign → NaN
                exp_result  = 8'hFF;
                mant_result = 28'h2000000;
                sign_result = 1'b0;
            end else begin
                exp_result  = 8'hFF;
                mant_result = 28'd0;
                sign_result = a_is_inf ? A_sign : B_sign;
            end

        end else begin
            // Normal finite subtraction (A + (-B)) with GRS
            if (A_exp > B_exp) begin
                diff = A_exp - B_exp;
                if (diff >= 27) begin
                    shifted_mant = 27'd0;
                    sticky_or = |B_mant;
                end else begin
                    shifted_mant = B_mant >> diff;
                    if (diff > 0)
                        sticky_or = |(B_mant & ((27'd1 << diff) - 27'd1));
                    else
                        sticky_or = 1'b0;
                    if (sticky_or)
                        shifted_mant[0] = 1'b1;
                end
                
                exp_result = A_exp;
                if (A_sign == B_sign)
                    mant_result = {1'b0, A_mant} + {1'b0, shifted_mant};
                else if (A_mant >= shifted_mant)
                    mant_result = {1'b0, A_mant} - {1'b0, shifted_mant};
                else
                    mant_result = {1'b0, shifted_mant} - {1'b0, A_mant};
                sign_result = (A_mant >= shifted_mant) ? A_sign : B_sign;

            end else if (B_exp > A_exp) begin
                diff = B_exp - A_exp;
                if (diff >= 27) begin
                    shifted_mant = 27'd0;
                    sticky_or = |A_mant;
                end else begin
                    shifted_mant = A_mant >> diff;
                    if (diff > 0)
                        sticky_or = |(A_mant & ((27'd1 << diff) - 27'd1));
                    else
                        sticky_or = 1'b0;
                    if (sticky_or)
                        shifted_mant[0] = 1'b1;
                end
                
                exp_result = B_exp;
                if (A_sign == B_sign)
                    mant_result = {1'b0, B_mant} + {1'b0, shifted_mant};
                else if (B_mant >= shifted_mant)
                    mant_result = {1'b0, B_mant} - {1'b0, shifted_mant};
                else
                    mant_result = {1'b0, shifted_mant} - {1'b0, B_mant};
                sign_result = (B_mant >= shifted_mant) ? B_sign : A_sign;

            end else begin
                exp_result = A_exp;
                if (A_sign == B_sign)
                    mant_result = {1'b0, A_mant} + {1'b0, B_mant};
                else if (A_mant >= B_mant)
                    mant_result = {1'b0, A_mant} - {1'b0, B_mant};
                else
                    mant_result = {1'b0, B_mant} - {1'b0, A_mant};
                sign_result = (A_mant >= B_mant) ? A_sign : B_sign;
            end

            if (mant_result == 0) begin
                exp_result  = 8'd0;
                sign_result = 1'b0;
            end
        end

        // Priority hierarchy for IEEE-754 compliance
        if (a_is_nan || b_is_nan) begin
            out_sign     <= 1'b0;
            out_exponent <= 8'hFF;
            out_mantissa <= 28'h2000000;
        end else if (a_is_inf && b_is_inf && (A_sign != B_sign)) begin
            out_sign     <= 1'b0;
            out_exponent <= 8'hFF;
            out_mantissa <= 28'h2000000;
        end else if (use_csd_result) begin
            out_sign     <= csd_result_sign;
            out_exponent <= csd_result_exp;
            out_mantissa <= csd_result_mant;
        end else begin
            out_sign     <= sign_result;
            out_exponent <= exp_result;
            out_mantissa <= mant_result;
        end
    end
end

endmodule

//==============================================================================
// IEEE754 SUBTRACTOR - STAGE 3
// Normalizes, rounds (GRS bits), and packs IEEE754 result
//==============================================================================
module ieee754_subtractor_stage3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
        input  logic        ex_stall,
    input  logic        en_fsub,
    input  logic        in_sign,
    input  logic [7:0]  in_exponent,
    input  logic [27:0] in_mantissa,
    input  logic [2:0]  rm,
    output logic [31:0] result,
    output logic [4:0]  flags
);

logic [31:0] result_reg;
logic [4:0]  flags_reg;
logic [2:0]  grs_bits;

always_ff @(posedge clk) begin
    if (reset) begin
        result_reg <= 32'd0;
        grs_bits   <= 3'b000;
    end else if (!stall ) begin     ///&& en_fsub
        logic [7:0]  norm_exp;
        logic [27:0] norm_mant;
        logic [24:0] mant_rounded_wide;
        int lz;
        logic [31:0] result_temp;
        logic guard, round, sticky;

        norm_exp  = in_exponent;
        norm_mant = in_mantissa;
        result_temp = 32'd0;
        lz = 0;

        if (norm_exp == 8'hFF) begin
            result_temp = {in_sign, norm_exp, norm_mant[25:3]};
        end else if (norm_mant == 28'd0) begin
            result_temp = 32'd0;
        end else begin
            // Normalize
            if (norm_mant[27]) begin
                norm_exp  = norm_exp + 1;
                norm_mant = norm_mant >> 1;
            end else if (norm_mant[26]) begin
                // Normal case
            end else begin
                for (lz = 0; lz < 27; lz++) begin
                    if (norm_mant[26 - lz]) break;
                end
                if (norm_exp > lz) begin
                    norm_exp  = norm_exp - lz;
                    norm_mant = norm_mant << lz;
                end else begin
                    norm_mant = norm_mant << (norm_exp - 1);
                    norm_exp  = 0;
                end
            end

            guard  = norm_mant[2];
            round  = norm_mant[1];
            sticky = norm_mant[0];
            grs_bits = {guard, round, sticky};

            // Round according to mode
            case (rm)
                3'b000: if (guard && (round || sticky || norm_mant[3])) mant_rounded_wide = {1'b0, norm_mant[26:3]} + 25'd1; else mant_rounded_wide = {1'b0, norm_mant[26:3]};
                3'b001: mant_rounded_wide = {1'b0, norm_mant[26:3]};
                3'b010: if (in_sign && (guard || round || sticky)) mant_rounded_wide = {1'b0, norm_mant[26:3]} + 25'd1; else mant_rounded_wide = {1'b0, norm_mant[26:3]};
                3'b011: if (!in_sign && (guard || round || sticky)) mant_rounded_wide = {1'b0, norm_mant[26:3]} + 25'd1; else mant_rounded_wide = {1'b0, norm_mant[26:3]};
                3'b100: if (guard) mant_rounded_wide = {1'b0, norm_mant[26:3]} + 25'd1; else mant_rounded_wide = {1'b0, norm_mant[26:3]};
                default: if (guard && (round || sticky || norm_mant[3])) mant_rounded_wide = {1'b0, norm_mant[26:3]} + 25'd1; else mant_rounded_wide = {1'b0, norm_mant[26:3]};
            endcase

            if (mant_rounded_wide[24]) begin
                norm_exp = norm_exp + 1;
            end

            if (norm_exp >= 8'hFF)
                result_temp = {in_sign, 8'hFF, 23'd0};
            else if (norm_exp == 8'd0)
                result_temp = {in_sign, 8'd0, 23'd0};
            else
                result_temp = {in_sign, norm_exp, mant_rounded_wide[22:0]};
        end

        result_reg <= result_temp;
    end
end

// Exception flags
always_ff @(posedge clk) begin
    if (reset) begin
        flags_reg <= 5'b00000;
    end else if (!stall ) begin  //&& en_fsub
        logic nv, dz, of, uf, nx;
        
        nv = (in_exponent == 8'hFF) && (in_mantissa[25:3] != 23'd0);
        dz = 1'b0;
        of = (result_reg[30:23] == 8'hFF) && (result_reg[22:0] == 23'd0);
        uf = (result_reg[30:23] == 8'd0) && (result_reg[22:0] != 23'd0);
        nx = |grs_bits;
        
        flags_reg <= {nv, dz, of, uf, nx};
    end
end

assign result = result_reg;
assign flags = flags_reg;

endmodule


