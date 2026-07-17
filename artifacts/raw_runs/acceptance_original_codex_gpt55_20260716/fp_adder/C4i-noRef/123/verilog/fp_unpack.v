`timescale 1ns/1ps

module fp_unpack #(
    parameter integer WIDTH      = 32,
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input  [WIDTH-1:0]       a,
    input  [WIDTH-1:0]       b,

    output                   sign_a,
    output                   sign_b,

    output [EXP_WIDTH-1:0]   exp_a,
    output [EXP_WIDTH-1:0]   exp_b,
    output [EXP_WIDTH-1:0]   exp_eff_a,
    output [EXP_WIDTH-1:0]   exp_eff_b,

    output [MANT_WIDTH-1:0]  frac_a,
    output [MANT_WIDTH-1:0]  frac_b,

    output [MANT_WIDTH:0]    mant_a,
    output [MANT_WIDTH:0]    mant_b,
    output [MANT_WIDTH:0]    sig_a,
    output [MANT_WIDTH:0]    sig_b,

    output                   zero_a,
    output                   zero_b,
    output                   inf_a,
    output                   inf_b,
    output                   nan_a,
    output                   nan_b,
    output                   sub_a,
    output                   sub_b,
    output                   denorm_a,
    output                   denorm_b
);

    localparam [EXP_WIDTH-1:0]  EXP_ZERO  = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0]  EXP_ONES  = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] FRAC_ZERO = {MANT_WIDTH{1'b0}};

    wire exp_zero_a;
    wire exp_zero_b;
    wire exp_ones_a;
    wire exp_ones_b;
    wire frac_zero_a;
    wire frac_zero_b;

    assign sign_a = a[WIDTH-1];
    assign sign_b = b[WIDTH-1];

    assign exp_a = a[WIDTH-2:MANT_WIDTH];
    assign exp_b = b[WIDTH-2:MANT_WIDTH];

    assign frac_a = a[MANT_WIDTH-1:0];
    assign frac_b = b[MANT_WIDTH-1:0];

    assign exp_zero_a  = (exp_a == EXP_ZERO);
    assign exp_zero_b  = (exp_b == EXP_ZERO);
    assign exp_ones_a  = (exp_a == EXP_ONES);
    assign exp_ones_b  = (exp_b == EXP_ONES);
    assign frac_zero_a = (frac_a == FRAC_ZERO);
    assign frac_zero_b = (frac_b == FRAC_ZERO);

    assign zero_a = exp_zero_a && frac_zero_a;
    assign zero_b = exp_zero_b && frac_zero_b;

    assign sub_a = exp_zero_a && !frac_zero_a;
    assign sub_b = exp_zero_b && !frac_zero_b;

    assign denorm_a = sub_a;
    assign denorm_b = sub_b;

    assign inf_a = exp_ones_a && frac_zero_a;
    assign inf_b = exp_ones_b && frac_zero_b;

    assign nan_a = exp_ones_a && !frac_zero_a;
    assign nan_b = exp_ones_b && !frac_zero_b;

    assign exp_eff_a = exp_zero_a ? {{(EXP_WIDTH-1){1'b0}}, 1'b1} : exp_a;
    assign exp_eff_b = exp_zero_b ? {{(EXP_WIDTH-1){1'b0}}, 1'b1} : exp_b;

    assign mant_a = exp_zero_a ? {1'b0, frac_a} : {1'b1, frac_a};
    assign mant_b = exp_zero_b ? {1'b0, frac_b} : {1'b1, frac_b};

    assign sig_a = mant_a;
    assign sig_b = mant_b;

endmodule