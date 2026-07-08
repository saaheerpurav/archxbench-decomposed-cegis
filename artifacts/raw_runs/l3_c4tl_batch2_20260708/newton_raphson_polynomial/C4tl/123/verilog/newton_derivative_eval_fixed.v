`timescale 1ns/1ps

module newton_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = WIDTH * 4
)(
    input signed [EXT_WIDTH-1:0] x,
    input signed [EXT_WIDTH-1:0] coeff1,
    input signed [EXT_WIDTH-1:0] coeff2,
    input signed [EXT_WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] derivative
);

    wire signed [EXT_WIDTH-1:0] two_coeff2;
    wire signed [EXT_WIDTH-1:0] three_coeff3;
    wire signed [(2*EXT_WIDTH)-1:0] mult_stage0;
    wire signed [(2*EXT_WIDTH)-1:0] mult_stage1;
    wire signed [EXT_WIDTH-1:0] stage0;
    wire signed [EXT_WIDTH-1:0] stage1;

    assign two_coeff2 = coeff2 << 1;
    assign three_coeff3 = (coeff3 << 1) + coeff3;

    assign mult_stage0 = three_coeff3 * x;
    assign stage0 = (mult_stage0 >>> FRAC) + two_coeff2;

    assign mult_stage1 = stage0 * x;
    assign stage1 = (mult_stage1 >>> FRAC) + coeff1;

    assign derivative = stage1;

endmodule