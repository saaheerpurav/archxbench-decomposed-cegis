`timescale 1ns/1ps

module harris_gradient_products #(
    parameter GRAD_W = 16
) (
    input signed [GRAD_W-1:0] grad_x,
    input signed [GRAD_W-1:0] grad_y,
    output [2*GRAD_W-1:0] ix2,
    output [2*GRAD_W-1:0] iy2,
    output signed [2*GRAD_W-1:0] ixy
);

    assign ix2 = grad_x * grad_x;
    assign iy2 = grad_y * grad_y;
    assign ixy = grad_x * grad_y;

endmodule