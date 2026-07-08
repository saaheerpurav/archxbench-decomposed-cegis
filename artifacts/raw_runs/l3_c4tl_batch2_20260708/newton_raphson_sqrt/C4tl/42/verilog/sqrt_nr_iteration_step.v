`timescale 1ns/1ps

module sqrt_nr_iteration_step #(
    parameter N = 16
)(
    input  wire [N-1:0] y_current,
    input  wire [N-1:0] quotient,
    output wire [N-1:0] y_next
);

    wire [N:0] sum;

    assign sum = {1'b0, y_current} + {1'b0, quotient};
    assign y_next = sum[N:1];

endmodule