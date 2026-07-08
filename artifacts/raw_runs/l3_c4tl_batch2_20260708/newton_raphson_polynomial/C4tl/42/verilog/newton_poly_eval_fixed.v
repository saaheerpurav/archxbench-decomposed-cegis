`timescale 1ns/1ps

module newton_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] poly
);

    wire signed [EXT_WIDTH-1:0] c0_ext = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT_WIDTH-1:0] c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT_WIDTH-1:0] c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT_WIDTH-1:0] c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;
    wire signed [(2*EXT_WIDTH)-1:0] mult2;

    wire signed [EXT_WIDTH-1:0] stage0;
    wire signed [EXT_WIDTH-1:0] stage1;
    wire signed [EXT_WIDTH-1:0] stage2;

    assign mult0 = c3_ext * x;
    assign stage0 = (mult0 >>> FRAC) + c2_ext;

    assign mult1 = stage0 * x;
    assign stage1 = (mult1 >>> FRAC) + c1_ext;

    assign mult2 = stage1 * x;
    assign stage2 = (mult2 >>> FRAC) + c0_ext;

    assign poly = stage2;

endmodule