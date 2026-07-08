`timescale 1ns/1ps

module nr_poly_derivative_cubic #(
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

    wire signed [EXT_WIDTH-1:0] three_c3;
    wire signed [EXT_WIDTH-1:0] two_c2;
    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;
    wire signed [EXT_WIDTH-1:0] term0;
    wire signed [EXT_WIDTH-1:0] term1;

    assign three_c3 = (coeff3 << 1) + coeff3;
    assign two_c2 = coeff2 << 1;

    assign mult0 = three_c3 * x;
    assign term0 = (mult0 >>> FRAC) + two_c2;

    assign mult1 = term0 * x;
    assign term1 = (mult1 >>> FRAC) + coeff1;

    assign derivative = term1;

endmodule