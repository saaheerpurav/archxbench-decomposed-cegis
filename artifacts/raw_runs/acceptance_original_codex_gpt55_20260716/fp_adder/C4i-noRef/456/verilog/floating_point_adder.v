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
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan, a_denorm, b_denorm;

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire align_sign_big, align_sign_small;
    wire [EXP_WIDTH:0] align_exp;
    wire [MANT_WIDTH+3:0] align_sig_big, align_sig_small;
    wire align_subtract;

    wire add_sign;
    wire [EXP_WIDTH:0] add_exp;
    wire [MANT_WIDTH+4:0] add_sig;
    wire add_zero;

    wire [WIDTH-1:0] normal_sum;
    wire [2:0] normal_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_unpack (
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

    fp_special #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_special (
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
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fp_align #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_align (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm),
        .sign_big(align_sign_big),
        .sign_small(align_sign_small),
        .exp_big(align_exp),
        .sig_big(align_sig_big),
        .sig_small(align_sig_small),
        .subtract(align_subtract)
    );

    fp_addsub #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_addsub (
        .sign_big(align_sign_big),
        .sign_small(align_sign_small),
        .exp_in(align_exp),
        .sig_big(align_sig_big),
        .sig_small(align_sig_small),
        .subtract(align_subtract),
        .sign_out(add_sign),
        .exp_out(add_exp),
        .sig_out(add_sig),
        .is_zero(add_zero)
    );

    fp_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_norm_round (
        .sign_in(add_sign),
        .exp_in(add_exp),
        .sig_in(add_sig),
        .is_zero(add_zero),
        .rnd_mode(rnd_mode),
        .denorm_input(a_denorm | b_denorm),
        .result(normal_sum),
        .flags(normal_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else if (special_valid) begin
            sum <= special_sum;
            exception_flags <= special_flags;
        end else begin
            sum <= normal_sum;
            exception_flags <= normal_flags;
        end
    end

endmodule