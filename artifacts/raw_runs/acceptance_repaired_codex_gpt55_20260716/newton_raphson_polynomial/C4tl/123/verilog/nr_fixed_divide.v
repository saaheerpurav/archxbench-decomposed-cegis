`timescale 1ns/1ps

module nr_fixed_divide #(
    parameter WORK_WIDTH = 96,
    parameter WORK_FRAC = 24
)(
    input signed [WORK_WIDTH-1:0] numerator,
    input signed [WORK_WIDTH-1:0] denominator,
    output signed [WORK_WIDTH-1:0] quotient
);
    wire signed [(2*WORK_WIDTH)-1:0] scaled_num;

    assign scaled_num = {{WORK_WIDTH{numerator[WORK_WIDTH-1]}}, numerator} <<< WORK_FRAC;
    assign quotient = (denominator == 0) ? {WORK_WIDTH{1'b0}} : (scaled_num / denominator);
endmodule