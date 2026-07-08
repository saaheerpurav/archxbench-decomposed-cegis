`timescale 1ns/1ps

module nr_poly_eval_cubic #(
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

    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;
    wire signed [(2*EXT_WIDTH)-1:0] mult2;

    wire signed [EXT_WIDTH-1:0] term0;
    wire signed [EXT_WIDTH-1:0] term1;
    wire signed [EXT_WIDTH-1:0] term2;

    assign mult0 = coeff3 * x;
    assign term0 = (mult0 >>> FRAC) + coeff2;

    assign mult1 = term0 * x;
    assign term1 = (mult1 >>> FRAC) + coeff1;

    assign mult2 = term1 * x;
    assign term2 = (mult2 >>> FRAC) + coeff0;

    assign poly = term2;

endmodule