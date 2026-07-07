`timescale 1ns/1ps

module nr_fixed_div #(
    parameter FRAC = 8,
    parameter WIDE = 64
)(
    input signed [WIDE-1:0] numer,
    input signed [WIDE-1:0] denom,
    output signed [WIDE-1:0] quot
);

    wire signed [(2*WIDE)-1:0] scaled_numer;

    assign scaled_numer = {{WIDE{numer[WIDE-1]}}, numer} <<< FRAC;
    assign quot = (denom == {WIDE{1'b0}}) ? {WIDE{1'b0}} : (scaled_numer / denom);

endmodule