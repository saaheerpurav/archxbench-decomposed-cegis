`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WORK_WIDTH = 96,
    parameter WORK_FRAC = 24
)(
    input signed [WORK_WIDTH-1:0] x,
    input signed [WORK_WIDTH-1:0] coeff0,
    input signed [WORK_WIDTH-1:0] coeff1,
    input signed [WORK_WIDTH-1:0] coeff2,
    input signed [WORK_WIDTH-1:0] coeff3,
    output signed [WORK_WIDTH-1:0] p
);
    wire signed [(2*WORK_WIDTH)-1:0] m0;
    wire signed [(2*WORK_WIDTH)-1:0] m1;
    wire signed [(2*WORK_WIDTH)-1:0] m2;

    wire signed [WORK_WIDTH-1:0] h0;
    wire signed [WORK_WIDTH-1:0] h1;
    wire signed [WORK_WIDTH-1:0] h2;

    assign m0 = coeff3 * x;
    assign h0 = (m0 >>> WORK_FRAC) + coeff2;

    assign m1 = h0 * x;
    assign h1 = (m1 >>> WORK_FRAC) + coeff1;

    assign m2 = h1 * x;
    assign h2 = (m2 >>> WORK_FRAC) + coeff0;

    assign p = h2;
endmodule