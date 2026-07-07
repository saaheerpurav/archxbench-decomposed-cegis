`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 128,
    parameter FRAC = 32
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] p
);
    wire signed [(2*WIDTH)-1:0] mul0;
    wire signed [(2*WIDTH)-1:0] mul1;
    wire signed [(2*WIDTH)-1:0] mul2;

    wire signed [WIDTH-1:0] h0;
    wire signed [WIDTH-1:0] h1;
    wire signed [WIDTH-1:0] h2;

    assign mul0 = coeff3 * x;
    assign h0 = (mul0 >>> FRAC) + coeff2;

    assign mul1 = h0 * x;
    assign h1 = (mul1 >>> FRAC) + coeff1;

    assign mul2 = h1 * x;
    assign h2 = (mul2 >>> FRAC) + coeff0;

    assign p = h2;
endmodule