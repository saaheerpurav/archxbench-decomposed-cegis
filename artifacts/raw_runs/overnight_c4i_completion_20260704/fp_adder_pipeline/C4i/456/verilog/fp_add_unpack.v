`timescale 1ns/1ps

module fp_add_unpack (
    input  [31:0] a,
    input  [31:0] b,
    output        a_sign,
    output        b_sign,
    output [7:0]  a_exp,
    output [7:0]  b_exp,
    output [26:0] a_sig,
    output [26:0] b_sig,
    output        a_zero,
    output        b_zero,
    output        a_inf,
    output        b_inf,
    output        a_nan,
    output        b_nan
);

wire [7:0]  a_raw_exp;
wire [7:0]  b_raw_exp;
wire [22:0] a_frac;
wire [22:0] b_frac;

wire a_exp_zero;
wire b_exp_zero;
wire a_exp_all_ones;
wire b_exp_all_ones;
wire a_frac_zero;
wire b_frac_zero;

assign a_sign = a[31];
assign b_sign = b[31];

assign a_raw_exp = a[30:23];
assign b_raw_exp = b[30:23];
assign a_frac    = a[22:0];
assign b_frac    = b[22:0];

assign a_exp_zero     = (a_raw_exp == 8'h00);
assign b_exp_zero     = (b_raw_exp == 8'h00);
assign a_exp_all_ones = (a_raw_exp == 8'hff);
assign b_exp_all_ones = (b_raw_exp == 8'hff);
assign a_frac_zero    = (a_frac == 23'b0);
assign b_frac_zero    = (b_frac == 23'b0);

assign a_zero = a_exp_zero && a_frac_zero;
assign b_zero = b_exp_zero && b_frac_zero;

assign a_inf = a_exp_all_ones && a_frac_zero;
assign b_inf = b_exp_all_ones && b_frac_zero;

assign a_nan = a_exp_all_ones && !a_frac_zero;
assign b_nan = b_exp_all_ones && !b_frac_zero;

assign a_exp = a_exp_zero ? 8'h01 : a_raw_exp;
assign b_exp = b_exp_zero ? 8'h01 : b_raw_exp;

assign a_sig = a_zero ? 27'b0 : {(!a_exp_zero), a_frac, 3'b000};
assign b_sig = b_zero ? 27'b0 : {(!b_exp_zero), b_frac, 3'b000};

endmodule