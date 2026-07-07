`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
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

    wire signed [EXT-1:0] h2 = c3_ext;

    wire signed [(2*EXT)-1:0] prod_h2_x = h2 * x_ext;
    wire signed [(2*EXT)-1:0] prod_h2_x_scaled_full = prod_h2_x >>> FRAC;
    wire signed [EXT-1:0] term_h2_x = prod_h2_x_scaled_full[EXT-1:0];
    wire signed [EXT-1:0] h1 = c2_ext + term_h2_x;

    wire signed [(2*EXT)-1:0] prod_h1_x = h1 * x_ext;
    wire signed [(2*EXT)-1:0] prod_h1_x_scaled_full = prod_h1_x >>> FRAC;
    wire signed [EXT-1:0] term_h1_x = prod_h1_x_scaled_full[EXT-1:0];
    wire signed [EXT-1:0] h0 = c1_ext + term_h1_x;

    wire signed [(2*EXT)-1:0] prod_h0_x = h0 * x_ext;
    wire signed [(2*EXT)-1:0] prod_h0_x_scaled_full = prod_h0_x >>> FRAC;
    wire signed [EXT-1:0] term_h0_x = prod_h0_x_scaled_full[EXT-1:0];
    wire signed [EXT-1:0] hv = c0_ext + term_h0_x;

    assign p = hv[WIDTH-1:0];

endmodule