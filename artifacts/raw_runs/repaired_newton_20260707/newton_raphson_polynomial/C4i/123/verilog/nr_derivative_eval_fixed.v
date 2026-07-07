`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = WIDTH * 4
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] deriv
);

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [EXT_WIDTH-1:0] two_c2;
    wire signed [EXT_WIDTH-1:0] three_c3;

    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;

    wire signed [EXT_WIDTH-1:0] h0;

    assign x_ext  = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign two_c2   = c2_ext << 1;
    assign three_c3 = (c3_ext << 1) + c3_ext;

    assign mult0 = three_c3 * x_ext;
    assign h0 = (mult0 >>> FRAC) + two_c2;

    assign mult1 = h0 * x_ext;
    assign deriv = (mult1 >>> FRAC) + c1_ext;

endmodule