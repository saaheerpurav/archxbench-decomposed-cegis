`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] p
);
    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [(2*EXT)-1:0] prod0 = c3_ext * x_ext;
    wire signed [EXT-1:0]     term0 = prod0 >>> FRAC;
    wire signed [EXT-1:0]     h0    = term0 + c2_ext;

    wire signed [(2*EXT)-1:0] prod1 = h0 * x_ext;
    wire signed [EXT-1:0]     term1 = prod1 >>> FRAC;
    wire signed [EXT-1:0]     h1    = term1 + c1_ext;

    wire signed [(2*EXT)-1:0] prod2 = h1 * x_ext;
    wire signed [EXT-1:0]     term2 = prod2 >>> FRAC;
    wire signed [EXT-1:0]     h2    = term2 + c0_ext;

    assign p = h2[WIDTH-1:0];

endmodule