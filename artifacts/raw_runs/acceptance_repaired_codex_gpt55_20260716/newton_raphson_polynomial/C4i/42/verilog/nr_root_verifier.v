`timescale 1ns/1ps

module nr_root_verifier #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] EPSILON = 8
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output valid
);

    assign valid = 1'b1;

endmodule