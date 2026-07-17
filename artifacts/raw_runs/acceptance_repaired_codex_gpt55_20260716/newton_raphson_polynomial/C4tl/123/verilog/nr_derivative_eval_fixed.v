`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WORK_WIDTH = 96,
    parameter WORK_FRAC = 24
)(
    input signed [WORK_WIDTH-1:0] x,
    input signed [WORK_WIDTH-1:0] coeff1,
    input signed [WORK_WIDTH-1:0] coeff2,
    input signed [WORK_WIDTH-1:0] coeff3,
    output signed [WORK_WIDTH-1:0] dp
);
    wire signed [WORK_WIDTH-1:0] three_a3;
    wire signed [WORK_WIDTH-1:0] two_a2;
    wire signed [(2*WORK_WIDTH)-1:0] m0;
    wire signed [(2*WORK_WIDTH)-1:0] m1;
    wire signed [WORK_WIDTH-1:0] h0;

    assign three_a3 = (coeff3 <<< 1) + coeff3;
    assign two_a2 = coeff2 <<< 1;

    assign m0 = three_a3 * x;
    assign h0 = (m0 >>> WORK_FRAC) + two_a2;

    assign m1 = h0 * x;
    assign dp = (m1 >>> WORK_FRAC) + coeff1;
endmodule