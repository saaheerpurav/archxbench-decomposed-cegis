`timescale 1ns/1ps

module fixed_poly_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] result
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}},      x};
    wire signed [EXT-1:0] c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [(2*EXT)-1:0] mul0;
    wire signed [(2*EXT)-1:0] mul1;
    wire signed [(2*EXT)-1:0] mul2;

    wire signed [EXT-1:0] h0;
    wire signed [EXT-1:0] h1;
    wire signed [EXT-1:0] h2;

    assign mul0 = c3_ext * x_ext;
    assign h0   = (mul0 >>> FRAC) + c2_ext;

    assign mul1 = h0 * x_ext;
    assign h1   = (mul1 >>> FRAC) + c1_ext;

    assign mul2 = h1 * x_ext;
    assign h2   = (mul2 >>> FRAC) + c0_ext;

    assign result = h2[WIDTH-1:0];

endmodule