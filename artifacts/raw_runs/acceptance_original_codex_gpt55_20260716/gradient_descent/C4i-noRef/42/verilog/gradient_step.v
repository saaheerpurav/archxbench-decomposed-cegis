`timescale 1ns/1ps

module gradient_step #(
    parameter N = 16,
    parameter M = 8,
    parameter WIDE_W = 2*N
)(
    input  signed [N-1:0] alpha,
    input  signed [WIDE_W-1:0] derivative,
    output signed [WIDE_W-1:0] step
);

    wire signed [(N+WIDE_W)-1:0] product;
    wire signed [(N+WIDE_W)-1:0] scaled_product;

    assign product = alpha * derivative;
    assign scaled_product = product >>> M;
    assign step = scaled_product[WIDE_W-1:0];

endmodule