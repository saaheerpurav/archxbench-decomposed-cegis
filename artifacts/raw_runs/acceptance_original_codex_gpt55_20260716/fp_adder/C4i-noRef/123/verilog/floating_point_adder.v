`timescale 1ns/1ps

module floating_point_adder #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [MANT_WIDTH-1:0] frac_a, frac_b;
    wire [MANT_WIDTH:0] mant_a, mant_b;
    wire zero_a, zero_b, inf_a, inf_b, nan_a, nan_b, sub_a, sub_b;

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire align_sign_large, align_sign_small;
    wire [EXP_WIDTH-1:0] align_exp;
    wire [MANT_WIDTH+3:0] align_large_sig, align_small_sig;
    wire align_large_is_a;

    wire add_sign;
    wire [EXP_WIDTH-1:0] add_exp;
    wire [MANT_WIDTH+4:0] add_sig;
    wire add_zero;

    wire [WIDTH-1:0] normal_sum;
    wire [2:0] normal_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpacker (
        .a(a),
        .b(b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .zero_a(zero_a),
        .zero_b(zero_b),
        .inf_a(inf_a),
        .inf_b(inf_b),
        .nan_a(nan_a),
        .nan_b(nan_b),
        .sub_a(sub_a),
        .sub_b(sub_b)
    );

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) special_cases (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .zero_a(zero_a),
        .zero_b(zero_b),
        .inf_a(inf_a),
        .inf_b(inf_b),
        .nan_a(nan_a),
        .nan_b(nan_b),
        .special_valid(special_valid),
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fp_align #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) aligner (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .align_exp(align_exp),
        .large_sig(align_large_sig),
        .small_sig(align_small_sig),
        .sign_large(align_sign_large),
        .sign_small(align_sign_small),
        .large_is_a(align_large_is_a)
    );

    fp_addsub #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) addsub (
        .align_exp(align_exp),
        .large_sig(align_large_sig),
        .small_sig(align_small_sig),
        .sign_large(align_sign_large),
        .sign_small(align_sign_small),
        .result_sign(add_sign),
        .result_exp(add_exp),
        .result_sig(add_sig),
        .result_zero(add_zero)
    );

    fp_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) normalize_round (
        .result_sign(add_sign),
        .result_exp(add_exp),
        .result_sig(add_sig),
        .result_zero(add_zero),
        .rnd_mode(rnd_mode),
        .subnormal_input(sub_a | sub_b),
        .sum(normal_sum),
        .flags(normal_flags)
    );

    always @* begin
        if (rst) begin
            sum = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else if (special_valid) begin
            sum = special_sum;
            exception_flags = special_flags;
        end else begin
            sum = normal_sum;
            exception_flags = normal_flags;
        end
    end

endmodule