`timescale 1ns/1ps

module floating_point_multiplier #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] product,
    output reg [2:0] exception_flags
);

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [MANT_WIDTH-1:0] mant_a, mant_b;
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan, a_denorm, b_denorm;

    wire result_sign;
    wire special_valid;
    wire [WIDTH-1:0] special_product;
    wire [2:0] special_flags;

    wire [MANT_WIDTH:0] sig_a, sig_b;
    wire signed [EXP_WIDTH+1:0] exp_sum;
    wire [(2*(MANT_WIDTH+1))-1:0] sig_product;

    wire [WIDTH-1:0] normal_product;
    wire [2:0] normal_flags;

    fp_operand_decode #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) decode_a (
        .operand(a),
        .sign(sign_a),
        .exponent(exp_a),
        .mantissa(mant_a),
        .is_zero(a_zero),
        .is_inf(a_inf),
        .is_nan(a_nan),
        .is_denorm(a_denorm)
    );

    fp_operand_decode #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) decode_b (
        .operand(b),
        .sign(sign_b),
        .exponent(exp_b),
        .mantissa(mant_b),
        .is_zero(b_zero),
        .is_inf(b_inf),
        .is_nan(b_nan),
        .is_denorm(b_denorm)
    );

    fp_special_cases #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) special_cases (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .result_sign(result_sign),
        .special_valid(special_valid),
        .special_product(special_product),
        .special_flags(special_flags)
    );

    fp_significand_multiply #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) significand_multiply (
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .sig_a(sig_a),
        .sig_b(sig_b),
        .exp_sum(exp_sum),
        .sig_product(sig_product)
    );

    fp_normalize_round #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) normalize_round (
        .result_sign(result_sign),
        .exp_sum(exp_sum),
        .sig_product(sig_product),
        .rnd_mode(rnd_mode),
        .product(normal_product),
        .exception_flags(normal_flags)
    );

    always @(*) begin
        if (rst) begin
            product = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else if (special_valid) begin
            product = special_product;
            exception_flags = special_flags;
        end else begin
            product = normal_product;
            exception_flags = normal_flags;
        end
    end

endmodule