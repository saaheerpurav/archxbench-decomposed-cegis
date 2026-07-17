`timescale 1ns/1ps

module nr_root_verify #(
    parameter WORK_WIDTH = 96,
    parameter WORK_FRAC = 24,
    parameter FRAC = 8,
    parameter EPSILON = 8
)(
    input signed [WORK_WIDTH-1:0] p,
    output valid
);
    localparam integer SHIFT_UP = WORK_FRAC - FRAC;

    wire signed [WORK_WIDTH-1:0] tol;
    wire signed [WORK_WIDTH-1:0] abs_p;

    assign tol = {{(WORK_WIDTH-32){1'b0}}, EPSILON[31:0]} <<< SHIFT_UP;
    assign abs_p = p[WORK_WIDTH-1] ? -p : p;
    assign valid = (abs_p <= tol);
endmodule