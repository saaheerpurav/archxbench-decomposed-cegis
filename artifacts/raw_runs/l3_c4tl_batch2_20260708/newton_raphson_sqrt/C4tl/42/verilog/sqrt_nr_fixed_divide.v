`timescale 1ns/1ps

module sqrt_nr_fixed_divide #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] x,
    input  [N-1:0] y,
    output [N-1:0] quotient
);

    wire [N+M-1:0] scaled_x;
    wire [N+M-1:0] div_result;

    assign scaled_x  = {x, {M{1'b0}}};
    assign div_result = (y == {N{1'b0}}) ? {(N+M){1'b0}} : (scaled_x / y);

    assign quotient = (|div_result[N+M-1:N]) ? {N{1'b1}} : div_result[N-1:0];

endmodule