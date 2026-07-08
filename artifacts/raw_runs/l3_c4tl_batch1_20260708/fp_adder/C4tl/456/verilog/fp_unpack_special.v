`timescale 1ns/1ps

module fp_unpack_special #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0]      a,
    input  [WIDTH-1:0]      b,
    output                 sign_a,
    output                 sign_b,
    output [EXP_WIDTH-1:0] exp_a,
    output [EXP_WIDTH-1:0] exp_b,
    output [MANT_WIDTH-1:0] frac_a,
    output [MANT_WIDTH-1:0] frac_b,
    output                 a_zero,
    output                 b_zero,
    output                 a_inf,
    output                 b_inf,
    output                 a_nan,
    output                 b_nan,
    output                 a_denorm,
    output                 b_denorm
);

    localparam [EXP_WIDTH-1:0]  EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] FRAC_ZERO    = {MANT_WIDTH{1'b0}};

    assign sign_a = a[WIDTH-1];
    assign sign_b = b[WIDTH-1];

    assign exp_a = a[MANT_WIDTH + EXP_WIDTH - 1 : MANT_WIDTH];
    assign exp_b = b[MANT_WIDTH + EXP_WIDTH - 1 : MANT_WIDTH];

    assign frac_a = a[MANT_WIDTH-1:0];
    assign frac_b = b[MANT_WIDTH-1:0];

    assign a_zero   = (exp_a == EXP_ZERO)     && (frac_a == FRAC_ZERO);
    assign b_zero   = (exp_b == EXP_ZERO)     && (frac_b == FRAC_ZERO);

    assign a_denorm = (exp_a == EXP_ZERO)     && (frac_a != FRAC_ZERO);
    assign b_denorm = (exp_b == EXP_ZERO)     && (frac_b != FRAC_ZERO);

    assign a_inf    = (exp_a == EXP_ALL_ONES) && (frac_a == FRAC_ZERO);
    assign b_inf    = (exp_b == EXP_ALL_ONES) && (frac_b == FRAC_ZERO);

    assign a_nan    = (exp_a == EXP_ALL_ONES) && (frac_a != FRAC_ZERO);
    assign b_nan    = (exp_b == EXP_ALL_ONES) && (frac_b != FRAC_ZERO);

endmodule