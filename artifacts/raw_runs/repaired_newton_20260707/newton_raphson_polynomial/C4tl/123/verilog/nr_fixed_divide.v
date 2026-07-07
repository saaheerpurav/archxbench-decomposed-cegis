`timescale 1ns/1ps

module nr_fixed_divide #(
    parameter WIDTH = 128,
    parameter FRAC = 32
)(
    input signed [WIDTH-1:0] numerator,
    input signed [WIDTH-1:0] denominator,
    output signed [WIDTH-1:0] quotient
);
    wire signed [(2*WIDTH)-1:0] scaled_num;

    assign scaled_num = {{WIDTH{numerator[WIDTH-1]}}, numerator} <<< FRAC;
    assign quotient = (denominator == 0) ? {WIDTH{1'b0}} : (scaled_num / denominator);
endmodule