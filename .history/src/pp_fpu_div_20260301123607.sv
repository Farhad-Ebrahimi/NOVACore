//==============================================================================
// IEEE754 DIVIDER - STAGE 1 (Extract, Check, Align)
//==============================================================================
module ieee754_div_stage1 (
    input  logic        clk,
    input  logic        reset,
    input  logic       en_fdiv,
     input  logic        ex_stall,  
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        start,
    input  logic [2:0]  rm,
    
    output logic [31:0] x_val,
    output logic [31:0] y_val,
    output logic [7:0]  result_exp,
    output logic        result_sign,
    output logic        special_case,
    output logic [31:0] special_result,
    output logic [2:0]  rm_out,
    output logic        s1_valid
);

    logic [31:0] x_val_int;
    logic [31:0] y_val_int;
    logic [7:0]  result_exp_int;
    logic        result_sign_int;
    logic        special_case_int;
    logic [31:0] special_result_int;
    logic [2:0]  rm_int;
    logic       valid;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_val_int <= 0;
            y_val_int <= 0;
            result_exp_int <= 0;
            result_sign_int <= 0;
            special_case_int <= 0;
            special_result_int <= 0;
            rm_int <= 0;
            valid <= 0;
        end else if (start ) begin  //&& en_fdiv
            // --- Combinational Extraction ---
            logic sign_a, sign_b;
            logic [7:0] exp_a, exp_b;
            logic [31:0] mant_a, mant_b;
            logic a_nan, b_nan, a_inf, b_inf, a_zero, b_zero;
            
            sign_a = (a & 32'h80000000) != 0;
            sign_b = (b & 32'h80000000) != 0;
            exp_a  = (a & 32'h7F800000) >>> 23;
            exp_b  = (b & 32'h7F800000) >>> 23;
            mant_a = (a & 32'h7FFFFF) | 32'h800000;
            mant_b = (b & 32'h7FFFFF) | 32'h800000;
            
            // --- Check Special Cases ---
            a_nan  = (exp_a == 8'hFF) && ((a & 32'h7FFFFF) != 0);
            b_nan  = (exp_b == 8'hFF) && ((b & 32'h7FFFFF) != 0);
            a_inf  = (exp_a == 8'hFF) && ((a & 32'h7FFFFF) == 0);
            b_inf  = (exp_b == 8'hFF) && ((b & 32'h7FFFFF) == 0);
            a_zero = (exp_a == 0) && ((a & 32'h7FFFFF) == 0);
            b_zero = (exp_b == 0) && ((b & 32'h7FFFFF) == 0);

            result_sign_int <= sign_a ^ sign_b;
            special_case_int <= 1;

            if (a_nan || b_nan || (a_inf && b_inf) || (a_zero && b_zero)) begin
                special_result_int <= 32'h7fc00000;
            end else if (a_inf) begin
                special_result_int <= {sign_a ^ sign_b, 8'hFF, 23'd0};
            end else if (b_inf) begin
                special_result_int <= {sign_a ^ sign_b, 8'd0, 23'd0};
            end else if (a_zero) begin
                special_result_int <= {sign_a ^ sign_b, 8'd0, 23'd0};
            end else if (b_zero) begin
                special_result_int <= {sign_a ^ sign_b, 8'hFF, 23'd0};
            end else begin
                special_case_int <= 0;
                special_result_int <= 0;
            end

            // --- Align ---
            result_exp_int <= exp_a - exp_b + 127;
            
            if (mant_a < mant_b) begin
                x_val_int <= mant_a << 1;
                result_exp_int <= (exp_a - exp_b + 127) - 1;
            end else begin
                x_val_int <= mant_a;
            end
            y_val_int <= mant_b;

            rm_int <= rm;
            valid <= 1;
        end else begin
            valid <= 0;
        end
    end

    assign x_val = x_val_int;
    assign y_val = y_val_int;
    assign result_exp = result_exp_int;
    assign result_sign = result_sign_int;
    assign special_case = special_case_int;
    assign special_result = special_result_int;
    assign rm_out = rm_int;
    assign s1_valid = valid;

endmodule


//==============================================================================
// IEEE754 DIVIDER - STAGE 2 (Sequential Division Loop - Unrolled 2x)
//==============================================================================
module ieee754_div_stage2 (
    input  logic        clk,
    input  logic        reset,
     input  logic        ex_stall,  
    input  logic        en_fdiv,
    input  logic [31:0] x_val_in,
    input  logic [31:0] y_val_in,
    input  logic [7:0]  result_exp_in,
    input  logic        result_sign_in,
    input  logic        special_case_in,
    input  logic [31:0] special_result_in,
    input  logic [2:0]  rm_in,
    input  logic        valid_in,  //s1_valid_in
    
    output logic [31:0] quotient,
    output logic        sticky,
    output logic [7:0]  result_exp_out,
    output logic        result_sign_out,
    output logic        special_case_out,
    output logic [31:0] special_result_out,
    output logic [2:0]  rm_out,
    output logic        valid_out,  //s2_valid_out
    //output logic        s1_valid_out,
    output logic        busy      //s2_busy
);

    logic [4:0]  iter_count;
    logic [31:0] x_val_reg, y_val_reg, r_reg;
    logic        sticky_int;
    logic [31:0] quotient_int;
    logic [7:0]  result_exp_reg;
    logic        result_sign_reg;
    logic        special_case_reg;
    logic [31:0] special_result_reg;
    logic [2:0]  rm_reg;
    logic        valid_int;
    logic        busy_int;  //s2_busy

    //assign s1_valid_out = valid_in;  // need to check the flow///  okay so i have already done this here in stage1 to stage2

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_int <= 0;
            busy_int <= 0;
            iter_count <= 0;
            x_val_reg <= 0;
            y_val_reg <= 0;
            r_reg <= 0;
            sticky_int <= 0;
            quotient_int <= 0;
            rm_reg <= 0;
        end else   //if (en_fdiv) begin

        //if (en_fdiv) begin   /////

            if (valid_in && !busy_int ) begin   /// valid_in is s1_valid
                // Load from Stage 1
                x_val_reg <= x_val_in;
                y_val_reg <= y_val_in;
                result_exp_reg <= result_exp_in;
                result_sign_reg <= result_sign_in;
                special_case_reg <= special_case_in;
                special_result_reg <= special_result_in;
                rm_reg <= rm_in;
                
                r_reg <= 0;
                iter_count <= 0;
                busy_int <= 1;
                valid_int <= 0;
                
                // If special case, skip loop
                if (special_case_in) begin
                    busy_int <= 0;
                    valid_int <= 1;
                end  
            end 
            else if (busy_int) begin
                // --- Loop Unrolled Logic (2 bits per cycle) ---
                logic [31:0] diff1, rem1, step1_x;
                logic bit1;
                logic [31:0] diff2, rem2, step2_x;
                logic bit2;

                // Step 1
                diff1 = x_val_reg - y_val_reg;
                bit1  = (x_val_reg >= y_val_reg);
                rem1  = bit1 ? diff1 : x_val_reg;
                step1_x = rem1 <<< 1;

                // Step 2
                diff2 = step1_x - y_val_reg;
                bit2  = (step1_x >= y_val_reg);
                rem2  = bit2 ? diff2 : step1_x;
                step2_x = rem2 <<< 1;

                if (iter_count < 24) begin
                    r_reg <= (r_reg <<< 2) | {30'b0, bit1, bit2};
                    x_val_reg <= step2_x;
                    iter_count <= iter_count + 2;
                end else begin
                    // Final bit (25th)
                    r_reg <= (r_reg <<< 1) | {31'b0, bit1};
                    x_val_reg <= step1_x;
                    sticky_int <= (step1_x != 0);
                    quotient_int <= (r_reg <<< 1) | {31'b0, bit1};
                    
                    busy_int <= 0;
                    valid_int <= 1;
                end
            end else begin
                valid_int <= 0;
            end
        //end
        //end
    end

    assign quotient = quotient_int;
    assign sticky = sticky_int;
    assign result_exp_out = result_exp_reg;
    assign result_sign_out = result_sign_reg;
    assign special_case_out = special_case_reg;
    assign special_result_out = special_result_reg;
    assign rm_out = rm_reg;
    assign valid_out = valid_int;
    assign busy = busy_int;

endmodule


//==============================================================================
// IEEE754 DIVIDER - STAGE 3 (Normalize and Round)
//==============================================================================
module ieee754_div_stage3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        en_fdiv,
     input  logic        ex_stall,  
    input  logic [31:0] quotient_in,
    input  logic        sticky_in,
    input  logic [7:0]  result_exp_in,
    input  logic        result_sign_in,
    input  logic        special_case_in,
    input  logic [31:0] special_result_in,
    input  logic [2:0]  rm_in,
    input  logic        valid_in,  //s2_valid_in
    input  logic        busy_in,   //s2_busy_in
    input  logic        start,
    input  logic        s1_valid_out,   // need to check the flow    coming in from execution stage

    
    output logic [31:0] result,
    output logic [4:0]  flags,
    output logic        s3_busy,  // need to check the flow  ----- busy
    output logic        done
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= 0;
            done <= 0;
            flags <= 0;
        end else  begin //if (en_fdiv) begin
            done <= 0;
            if (valid_in ) begin
                if (special_case_in) begin
                    result <= special_result_in;
                    flags <= 0;
                    if (special_result_in[30:23] == 8'hFF && special_result_in[22:0] != 0) flags[4] <= 1;
                end else begin
                    logic [31:0] r_temp;
                    logic [7:0] shift;
                    logic guard, lsb, round_up;
                    
                    r_temp = quotient_in;
                    
                    if ((result_exp_in >= 1) && (result_exp_in <= 254)) begin
                        // Normal range - apply rounding
                        guard = r_temp[0];
                        lsb = r_temp[1];
                        
                        case (rm_in)
                            3'b000: round_up = guard && (sticky_in || lsb);
                            3'b001: round_up = 0;
                            3'b010: round_up = result_sign_in && (guard || sticky_in);
                            3'b011: round_up = !result_sign_in && (guard || sticky_in);
                            3'b100: round_up = guard;
                            default: round_up = guard && (sticky_in || lsb);
                        endcase
                        
                        r_temp = (r_temp >>> 1) + round_up;
                        r_temp = (result_exp_in <<< 23) + (r_temp - 32'h800000);
                        
                        flags <= 0;
                        if (guard || sticky_in) flags[0] <= 1;
                        
                    end else begin
                        if (result_exp_in > 254) begin
                            r_temp = 32'h7F800000;
                            flags <= 5'b00101;
                        end else begin
                            shift = 1 - result_exp_in;
                            if (shift > 25) shift = 25;
                            
                            r_temp = r_temp >>> shift;
                            
                            guard = r_temp[0];
                            lsb = r_temp[1];
                            
                            case (rm_in)
                                3'b000: round_up = guard && (sticky_in || lsb);
                                3'b001: round_up = 0;
                                3'b010: round_up = result_sign_in && (guard || sticky_in);
                                3'b011: round_up = !result_sign_in && (guard || sticky_in);
                                3'b100: round_up = guard;
                                default: round_up = guard && (sticky_in || lsb);
                            endcase
                            
                            r_temp = (r_temp >>> 1) + round_up;
                            
                            flags <= 5'b00011;
                        end
                    end
                    
                    result <= r_temp | (result_sign_in ? 32'h80000000 : 32'd0);
                end
                done <= 1;
                $display("[IEEE754_DIV_STAGE3_DONE] result=0x%08h at time %t", result, $time);
            end
            end
            end

    assign s3_busy = (start || valid_in || busy_in || s1_valid_out);
    //assign busy = (start || s2_valid || s2_busy || s1_valid);

endmodule
   