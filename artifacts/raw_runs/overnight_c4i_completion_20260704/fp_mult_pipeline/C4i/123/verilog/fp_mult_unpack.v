`timescale 1ns/1ps

module fp_mult_unpack (
    input  [31:0] a,
    input  [31:0] b,
    output        sign,
    output [7:0]  a_exp_eff,
    output [7:0]  b_exp_eff,
    output [23:0] a_mant,
    output [23:0] b_mant,
    output        a_zero,
    output        b_zero,
    output        a_inf,
    output        b_inf,
    output        a_nan,
    output        b_nan
);

wire [7:0]  a_exp;
wire [7:0]  b_exp;
wire [22:0] a_frac;
wire [22:0] b_frac;

assign a_exp  = a[30:23];
assign b_exp  = b[30:23];
assign a_frac = a[22:0];
assign b_frac = b[22:0];

assign sign = a[31] ^ b[31];

assign a_zero = (a_exp == 8'h00) && (a_frac == 23'h000000);
assign b_zero = (b_exp == 8'h00) && (b_frac == 23'h000000);

assign a_inf = (a_exp == 8'hff) && (a_frac == 23'h000000);
assign b_inf = (b_exp == 8'hff) && (b_frac == 23'h000000);

assign a_nan = (a_exp == 8'hff) && (a_frac != 23'h000000);
assign b_nan = (b_exp == 8'hff) && (b_frac != 23'h000000);

assign a_exp_eff = (a_exp == 8'h00) ? 8'h01 : a_exp;
assign b_exp_eff = (b_exp == 8'h00) ? 8'h01 : b_exp;

assign a_mant = (a_exp == 8'h00) ? {1'b0, a_frac} : {1'b1, a_frac};
assign b_mant = (b_exp == 8'h00) ? {1'b0, b_frac} : {1'b1, b_frac};

endmodule