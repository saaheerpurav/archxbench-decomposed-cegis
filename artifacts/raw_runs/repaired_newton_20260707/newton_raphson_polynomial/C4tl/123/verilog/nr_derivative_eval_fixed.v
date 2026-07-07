`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 128,
    parameter FRAC = 32
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] dp
);
    wire signed [WIDTH-1:0] three_c3;
    wire signed [WIDTH-1:0] two_c2;

    wire signed [(2*WIDTH)-1:0] mul0;
    wire signed [(2*WIDTH)-1:0] mul1;

    wire signed [WIDTH-1:0] h0;
    wire signed [WIDTH-1:0] h1;

    assign three_c3 = (coeff3 <<< 1) + coeff3;
    assign two_c2 = coeff2 <<< 1;

    assign mul0 = three_c3 * x;
    assign h0 = (mul0 >>> FRAC) + two_c2;

    assign mul1 = h0 * x;
    assign h1 = (mul1 >>> FRAC) + coeff1;

    assign dp = h1;
endmodule