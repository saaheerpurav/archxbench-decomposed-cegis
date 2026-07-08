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

    wire a_sign, b_sign;
    wire [EXP_WIDTH-1:0] a_exp, b_exp;
    wire [MANT_WIDTH-1:0] a_mant, b_mant;
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan, a_denorm, b_denorm;

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire big_sign, small_sign;
    wire [EXP_WIDTH:0] common_exp;
    wire [MANT_WIDTH+3:0] big_sig;
    wire [MANT_WIDTH+3:0] small_sig;
    wire any_denorm;

    wire raw_sign;
    wire [EXP_WIDTH:0] raw_exp;
    wire [MANT_WIDTH+4:0] raw_sig;
    wire raw_zero;

    wire [WIDTH-1:0] normal_sum;
    wire [2:0] normal_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_unpack (
        .a(a),
        .b(b),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_mant(a_mant),
        .b_mant(b_mant),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm)
    );

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_special (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .special_valid(special_valid),
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fp_align #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_align (
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_mant(a_mant),
        .b_mant(b_mant),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm),
        .big_sign(big_sign),
        .small_sign(small_sign),
        .common_exp(common_exp),
        .big_sig(big_sig),
        .small_sig(small_sig),
        .any_denorm(any_denorm)
    );

    fp_addsub #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_addsub (
        .big_sign(big_sign),
        .small_sign(small_sign),
        .common_exp(common_exp),
        .big_sig(big_sig),
        .small_sig(small_sig),
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig),
        .raw_zero(raw_zero)
    );

    fp_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_norm_round (
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig),
        .raw_zero(raw_zero),
        .rnd_mode(rnd_mode),
        .any_denorm(any_denorm),
        .result(normal_sum),
        .flags(normal_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else begin
            if (special_valid) begin
                sum <= special_sum;
                exception_flags <= special_flags;
            end else begin
                sum <= normal_sum;
                exception_flags <= normal_flags;
            end
        end
    end

endmodule