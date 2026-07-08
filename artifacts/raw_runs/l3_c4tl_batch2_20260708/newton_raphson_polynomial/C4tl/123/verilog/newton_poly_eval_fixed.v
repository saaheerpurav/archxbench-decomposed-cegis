`timescale 1ns/1ps

module newton_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = WIDTH * 4
)(
    input signed [EXT_WIDTH-1:0] x,
    input signed [EXT_WIDTH-1:0] coeff0,
    input signed [EXT_WIDTH-1:0] coeff1,
    input signed [EXT_WIDTH-1:0] coeff2,
    input signed [EXT_WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] poly
);

    wire signed [(2*EXT_WIDTH)-1:0] mult_stage0;
    wire signed [(2*EXT_WIDTH)-1:0] mult_stage1;
    wire signed [(2*EXT_WIDTH)-1:0] mult_stage2;

    wire signed [EXT_WIDTH-1:0] stage0;
    wire signed [EXT_WIDTH-1:0] stage1;
    wire signed [EXT_WIDTH-1:0] stage2;

    assign mult_stage0 = coeff3 * x;
    assign stage0 = (mult_stage0 >>> FRAC) + coeff2;

    assign mult_stage1 = stage0 * x;
    assign stage1 = (mult_stage1 >>> FRAC) + coeff1;

    assign mult_stage2 = stage1 * x;
    assign stage2 = (mult_stage2 >>> FRAC) + coeff0;

    assign poly = stage2;

endmodule