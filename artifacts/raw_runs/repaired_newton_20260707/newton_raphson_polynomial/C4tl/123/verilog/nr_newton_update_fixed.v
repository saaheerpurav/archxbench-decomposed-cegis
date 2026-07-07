`timescale 1ns/1ps

module nr_newton_update_fixed #(
    parameter WIDTH = 128
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] delta,
    input derivative_zero,
    output signed [WIDTH-1:0] x_next
);
    assign x_next = derivative_zero ? x : (x - delta);
endmodule