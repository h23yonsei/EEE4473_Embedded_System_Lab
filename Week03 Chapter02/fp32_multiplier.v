`timescale 1ns / 1ps
module fp32_multiplier(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);
    // sign, exponent, mantissa
    wire sign_a = a[31], sign_b = b[31];
    wire [7:0] exp_a = a[30:23], exp_b = b[30:23];
    wire [22:0] mant_a = a[22:0], mant_b = b[22:0];
    
    // calculate sign
    wire sign_out = sign_a ^ sign_b;

    // calculate product
    wire [23:0] num_a = {1'b1, mant_a};
    wire [23:0] num_b = {1'b1, mant_b};
    wire [47:0] prod = num_a * num_b;

    // calculate signed exp
    // 8bits for exp + 1bit for overflow + 1bit for sign 
    wire signed [9:0] signed_exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 10'sd127;

    // round product
    // 24bits MSB + 1bit for carry after round up
    // case 1: 2.f or 3.f --> will shift left once and increase exp later
    wire [24:0] prod_round_shift = prod[47:24] + prod[23];
    // case 2: product is 1.f
    wire [24:0] prod_round_norm  = prod[46:23] + prod[22];

    // final values
    reg [7:0]  final_exp;
    reg [22:0] final_mant;

    always @(*) begin
        // at least one number is zero
        if ((exp_a == 8'd0 && mant_a == 23'd0) || (exp_b == 8'd0 && mant_b == 23'd0)) begin
            final_exp  = 8'd0;
            final_mant = 23'd0;
        end
        // overflow
        else if (signed_exp_sum > 10'sd254) begin
            final_exp  = 8'hFF;
            final_mant = 23'd0;
        end
        // underflow
        else if (signed_exp_sum < -10'sd24) begin 
            final_exp  = 8'd0;
            final_mant = 23'd0;
        end
        // normal case
        else begin
            if (prod[47]) begin
                // case 1: increment exponent by 1
                final_exp  = signed_exp_sum[7:0] + 8'd1;
                final_mant = prod_round_shift[22:0];    // cut carry bit, cut MSB = the 1. part of 1.f
            end 
            else begin
                // case 2
                final_exp  = signed_exp_sum[7:0];
                final_mant = prod_round_norm[22:0];
            end
        end
    end
    
    assign result = {sign_out, final_exp, final_mant};

endmodule