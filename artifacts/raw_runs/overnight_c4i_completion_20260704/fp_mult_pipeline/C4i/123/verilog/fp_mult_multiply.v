`timescale 1ns/1ps

module fp_mult_multiply (
    input  [7:0]  a_exp_eff,
    input  [7:0]  b_exp_eff,
    input  [23:0] a_mant,
    input  [23:0] b_mant,
    output [47:0] product,
    output signed [10:0] exp_unbiased
);

assign product = a_mant * b_mant;

assign exp_unbiased =
    $signed({3'b000, a_exp_eff}) +
    $signed({3'b000, b_exp_eff}) -
    11'sd127;

endmodule