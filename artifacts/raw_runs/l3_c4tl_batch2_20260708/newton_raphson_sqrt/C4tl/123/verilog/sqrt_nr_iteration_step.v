`timescale 1ns/1ps

module sqrt_nr_iteration_step #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X_value,
    input  [N-1:0] y_value,
    output [N-1:0] y_next
);

    wire [N+M-1:0] scaled_x;
    wire [N+M-1:0] quotient_wide;
    wire [N-1:0] quotient_clamped;
    wire [N:0] sum_wide;

    assign scaled_x = {{M{1'b0}}, X_value} << M;

    assign quotient_wide =
        (y_value == {N{1'b0}}) ? {N+M{1'b0}} :
        scaled_x / y_value;

    assign quotient_clamped =
        (|quotient_wide[N+M-1:N]) ? {N{1'b1}} :
        quotient_wide[N-1:0];

    assign sum_wide = {1'b0, y_value} + {1'b0, quotient_clamped};

    assign y_next = sum_wide[N:1];

endmodule