`timescale 1ns/1ps

module fp_mult_round (
    input signed [10:0] exp_in,
    input [23:0] mant_in,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    output signed [10:0] exp_out,
    output [22:0] frac_out
);

wire lsb_even_tie_break;
wire increment;
wire [24:0] rounded;

assign lsb_even_tie_break = mant_in[0];
assign increment = guard_bit && (round_bit || sticky_bit || lsb_even_tie_break);

assign rounded = {1'b0, mant_in} + {24'b0, increment};

assign exp_out = rounded[24] ? (exp_in + 11'sd1) : exp_in;
assign frac_out = rounded[24] ? 23'b0 : rounded[22:0];

endmodule