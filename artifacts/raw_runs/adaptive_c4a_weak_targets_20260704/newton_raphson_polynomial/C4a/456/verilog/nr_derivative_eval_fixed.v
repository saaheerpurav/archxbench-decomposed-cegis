`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] derivative
);

    localparam PROD2_WIDTH = 2 * WIDTH;
    localparam PROD3_WIDTH = 3 * WIDTH;
    localparam ACC_WIDTH   = (3 * WIDTH) + 4;

    wire signed [PROD2_WIDTH-1:0] coeff2_x;
    wire signed [PROD2_WIDTH-1:0] coeff3_x;
    wire signed [PROD3_WIDTH-1:0] coeff3_x2;

    wire signed [ACC_WIDTH-1:0] term_coeff1;
    wire signed [ACC_WIDTH-1:0] term_2_coeff2_x;
    wire signed [ACC_WIDTH-1:0] term_3_coeff3_x2;
    wire signed [ACC_WIDTH-1:0] derivative_wide;

    assign coeff2_x  = coeff2 * x;
    assign coeff3_x  = coeff3 * x;
    assign coeff3_x2 = coeff3_x * x;

    assign term_coeff1 = {{(ACC_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};

    assign term_2_coeff2_x =
        ({{(ACC_WIDTH-PROD2_WIDTH){coeff2_x[PROD2_WIDTH-1]}}, coeff2_x} << 1) >>> FRAC;

    assign term_3_coeff3_x2 =
        (({{(ACC_WIDTH-PROD3_WIDTH){coeff3_x2[PROD3_WIDTH-1]}}, coeff3_x2} << 1) +
          {{(ACC_WIDTH-PROD3_WIDTH){coeff3_x2[PROD3_WIDTH-1]}}, coeff3_x2}) >>> (2 * FRAC);

    assign derivative_wide = term_coeff1 + term_2_coeff2_x + term_3_coeff3_x2;

    assign derivative = derivative_wide[WIDTH-1:0];

endmodule