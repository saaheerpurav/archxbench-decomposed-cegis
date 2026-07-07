`timescale 1ns/1ps

module nr_derivative_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [(4*WIDTH)-1:0] derivative
);

    localparam EXT  = 4 * WIDTH;
    localparam PROD = 2 * EXT;

    wire signed [EXT-1:0] x_ext;
    wire signed [EXT-1:0] c1_ext;
    wire signed [EXT-1:0] c2_ext;
    wire signed [EXT-1:0] c3_ext;

    wire signed [PROD-1:0] x_sq_prod;
    wire signed [EXT-1:0]  x_sq;

    wire signed [PROD-1:0] c2_x_prod;
    wire signed [EXT-1:0]  c2_x;

    wire signed [PROD-1:0] c3_xsq_prod;
    wire signed [EXT-1:0]  c3_xsq;

    wire signed [EXT-1:0] term_linear;
    wire signed [EXT-1:0] term_cubic;

    assign x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    assign c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign x_sq_prod = x_ext * x_ext;
    assign x_sq      = $signed(x_sq_prod >>> FRAC);

    assign c2_x_prod = c2_ext * x_ext;
    assign c2_x      = $signed(c2_x_prod >>> FRAC);

    assign c3_xsq_prod = c3_ext * x_sq;
    assign c3_xsq      = $signed(c3_xsq_prod >>> FRAC);

    assign term_linear = c2_x << 1;
    assign term_cubic  = c3_xsq + (c3_xsq << 1);

    assign derivative = c1_ext + term_linear + term_cubic;

endmodule