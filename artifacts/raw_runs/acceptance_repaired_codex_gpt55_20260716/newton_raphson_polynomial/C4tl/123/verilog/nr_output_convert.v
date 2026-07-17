`timescale 1ns/1ps

module nr_output_convert #(
    parameter WIDTH = 16,
    parameter WORK_WIDTH = 96,
    parameter FRAC = 8,
    parameter WORK_FRAC = 24
)(
    input signed [WORK_WIDTH-1:0] x,
    output signed [WIDTH-1:0] root
);
    localparam integer DOWN_SHIFT = WORK_FRAC - FRAC;

    wire signed [WORK_WIDTH-1:0] shifted_floor;
    wire signed [WORK_WIDTH-1:0] frac_mask;
    wire has_fraction;
    wire signed [WORK_WIDTH-1:0] shifted_trunc;

    assign shifted_floor = x >>> DOWN_SHIFT;
    assign frac_mask = ({{(WORK_WIDTH-1){1'b0}}, 1'b1} <<< DOWN_SHIFT) - 1'b1;
    assign has_fraction = |(x & frac_mask);
    assign shifted_trunc = (x[WORK_WIDTH-1] && has_fraction) ? (shifted_floor + 1'b1) : shifted_floor;

    assign root = shifted_trunc[WIDTH-1:0];
endmodule