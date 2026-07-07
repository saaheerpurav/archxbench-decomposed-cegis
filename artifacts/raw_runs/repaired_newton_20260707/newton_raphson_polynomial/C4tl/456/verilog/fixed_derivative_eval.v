`timescale 1ns/1ps

module fixed_derivative_eval #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] result
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}},      x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [(2*EXT)-1:0] h1_mul;
    wire signed [(2*EXT)-1:0] h2_mul;

    wire signed [EXT-1:0] h1;
    wire signed [EXT-1:0] h2;

    assign h1_mul = three_c3 * x_ext;
    assign h1     = (h1_mul >>> FRAC) + two_c2;

    assign h2_mul = h1 * x_ext;
    assign h2     = (h2_mul >>> FRAC) + c1_ext;

    assign result = h2[WIDTH-1:0];

endmodule