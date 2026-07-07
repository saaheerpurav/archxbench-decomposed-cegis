`timescale 1ns/1ps

module nr_newton_update #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] delta,
    input  derivative_zero,
    output signed [WIDTH-1:0] x_next
);

    wire signed [WIDTH:0] x_ext;
    wire signed [WIDTH:0] delta_ext;
    wire signed [WIDTH:0] next_ext;

    assign x_ext     = {x[WIDTH-1], x};
    assign delta_ext = {delta[WIDTH-1], delta};

    assign next_ext = x_ext - delta_ext;

    assign x_next = derivative_zero ? x : next_ext[WIDTH-1:0];

endmodule