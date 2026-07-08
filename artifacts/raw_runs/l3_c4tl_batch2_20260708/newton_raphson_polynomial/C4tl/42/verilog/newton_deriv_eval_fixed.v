`timescale 1ns/1ps

module newton_deriv_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] deriv
);

    wire signed [EXT_WIDTH-1:0] c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT_WIDTH-1:0] c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT_WIDTH-1:0] c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT_WIDTH-1:0] two_c2 = c2_ext <<< 1;
    wire signed [EXT_WIDTH-1:0] three_c3 = (c3_ext <<< 1) + c3_ext;

    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;

    wire signed [EXT_WIDTH-1:0] stage0;
    wire signed [EXT_WIDTH-1:0] stage1;

    assign mult0 = three_c3 * x;
    assign stage0 = (mult0 >>> FRAC) + two_c2;

    assign mult1 = stage0 * x;
    assign stage1 = (mult1 >>> FRAC) + c1_ext;

    assign deriv = stage1;

endmodule