`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    input  signed [WIDTH-1:0] tolerance,
    output valid
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};
    wire signed [EXT-1:0] tol_ext = {{(EXT-WIDTH){tolerance[WIDTH-1]}}, tolerance};

    wire signed [EXT-1:0] x2;
    wire signed [EXT-1:0] x3;
    wire signed [EXT-1:0] term1;
    wire signed [EXT-1:0] term2;
    wire signed [EXT-1:0] term3;
    wire signed [EXT-1:0] p_ext;

    assign x2 = (x_ext * x_ext) >>> FRAC;
    assign x3 = (x2 * x_ext) >>> FRAC;

    assign term1 = (c1_ext * x_ext) >>> FRAC;
    assign term2 = (c2_ext * x2) >>> FRAC;
    assign term3 = (c3_ext * x3) >>> FRAC;

    assign p_ext = c0_ext + term1 + term2 + term3;

    wire signed [EXT-1:0] abs_p;
    wire signed [EXT-1:0] abs_tol;

    assign abs_p   = p_ext[EXT-1]   ? -p_ext   : p_ext;
    assign abs_tol = tol_ext[EXT-1] ? -tol_ext : tol_ext;

    assign valid = (abs_p <= abs_tol);

endmodule