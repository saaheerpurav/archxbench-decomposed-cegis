`timescale 1ns/1ps

module fixed_newton_step #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] delta,
    input                     hold,
    output signed [WIDTH-1:0] x_next
);

    assign x_next = hold ? x : (x - delta);

endmodule