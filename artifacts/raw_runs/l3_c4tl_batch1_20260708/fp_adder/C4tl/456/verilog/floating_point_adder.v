`timescale 1ns/1ps

module floating_point_adder #(
    parameter integer WIDTH = 32
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);

    localparam integer EXP_WIDTH  = 8;
    localparam integer MANT_WIDTH = 23;

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [MANT_WIDTH-1:0] frac_a, frac_b;
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan, a_denorm, b_denorm;

    fp_unpack_special #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_i (
        .a(a),
        .b(b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm)
    );

    wire special_valid;
    wire [WIDTH-1:0] special_result;
    wire [2:0] special_flags;

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) special_i (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .special_valid(special_valid),
        .special_result(special_result),
        .special_flags(special_flags)
    );

    wire aligned_sign_big, aligned_sign_small;
    wire [EXP_WIDTH-1:0] aligned_exp;
    wire [MANT_WIDTH+3:0] aligned_big;
    wire [MANT_WIDTH+3:0] aligned_small;

    fp_align #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) align_i (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .aligned_sign_big(aligned_sign_big),
        .aligned_sign_small(aligned_sign_small),
        .aligned_exp(aligned_exp),
        .aligned_big(aligned_big),
        .aligned_small(aligned_small)
    );

    wire raw_sign;
    wire [EXP_WIDTH-1:0] raw_exp;
    wire [MANT_WIDTH+4:0] raw_sum;
    wire raw_zero;

    fp_addsub #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) addsub_i (
        .sign_big(aligned_sign_big),
        .sign_small(aligned_sign_small),
        .aligned_exp(aligned_exp),
        .mant_big(aligned_big),
        .mant_small(aligned_small),
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sum(raw_sum),
        .raw_zero(raw_zero)
    );

    wire [WIDTH-1:0] normal_result;
    wire [2:0] normal_flags;

    fp_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) norm_i (
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sum(raw_sum),
        .raw_zero(raw_zero),
        .rnd_mode(rnd_mode),
        .underflow_hint(a_denorm | b_denorm),
        .result(normal_result),
        .flags(normal_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else begin
            if (special_valid) begin
                sum <= special_result;
                exception_flags <= special_flags;
            end else begin
                sum <= normal_result;
                exception_flags <= normal_flags;
            end
        end
    end

endmodule