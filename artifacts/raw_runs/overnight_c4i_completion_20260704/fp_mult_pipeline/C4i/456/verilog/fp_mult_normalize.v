`timescale 1ns/1ps

module fp_mult_normalize (
    input  [47:0] product,
    input  signed [10:0] exp_in,
    output signed [10:0] exp_norm,
    output [23:0] mant_norm,
    output guard_bit,
    output round_bit,
    output sticky_bit
);

wire product_ge_two;

assign product_ge_two = product[47];

assign exp_norm = product_ge_two ? (exp_in + 11'sd1) : exp_in;

assign mant_norm = product_ge_two ? product[47:24] : product[46:23];

assign guard_bit  = product_ge_two ? product[23] : product[22];
assign round_bit  = product_ge_two ? product[22] : product[21];
assign sticky_bit = product_ge_two ? (|product[21:0]) : (|product[20:0]);

endmodule