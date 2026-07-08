`timescale 1ns/1ps

module fpa_add_core #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output [WIDTH-1:0] result,
    output [2:0] flags
);
    wire sign_a;
    wire sign_b;
    wire [EXP_WIDTH-1:0] exp_a;
    wire [EXP_WIDTH-1:0] exp_b;
    wire [MANT_WIDTH-1:0] frac_a;
    wire [MANT_WIDTH-1:0] frac_b;

    wire [EXP_WIDTH:0] exp_big;
    wire sign_big;
    wire sign_small;
    wire [MANT_WIDTH+3:0] sig_big;
    wire [MANT_WIDTH+3:0] sig_small;
    wire any_subnormal;

    wire op_sub;
    wire raw_sign;
    wire [EXP_WIDTH:0] raw_exp;
    wire [MANT_WIDTH+4:0] raw_sig;
    wire raw_zero;

    fpa_unpack_align #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_align (
        .a(a),
        .b(b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .exp_big(exp_big),
        .sign_big(sign_big),
        .sign_small(sign_small),
        .sig_big(sig_big),
        .sig_small(sig_small),
        .any_subnormal(any_subnormal)
    );

    fpa_significand_add #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_add (
        .sign_big(sign_big),
        .sign_small(sign_small),
        .exp_big(exp_big),
        .sig_big(sig_big),
        .sig_small(sig_small),
        .rnd_mode(rnd_mode),
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig),
        .raw_zero(raw_zero),
        .op_sub(op_sub)
    );

    fpa_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_norm (
        .raw_sign(raw_sign),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig),
        .raw_zero(raw_zero),
        .any_subnormal(any_subnormal),
        .rnd_mode(rnd_mode),
        .result(result),
        .flags(flags)
    );

endmodule