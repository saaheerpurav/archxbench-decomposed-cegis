`timescale 1ns/1ps

module nr_newton_update #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] x_current,
    input  signed [WIDTH-1:0] step,
    output signed [WIDTH-1:0] x_next
);

    assign x_next = x_current - step;

endmodule