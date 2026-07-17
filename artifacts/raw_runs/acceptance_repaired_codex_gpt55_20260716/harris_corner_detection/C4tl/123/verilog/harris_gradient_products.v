`timescale 1ns/1ps

module harris_gradient_products #(
    parameter GRAD_W = 16
) (
    input signed [GRAD_W-1:0] ix,
    input signed [GRAD_W-1:0] iy,
    output [2*GRAD_W-1:0] ix2,
    output [2*GRAD_W-1:0] iy2,
    output signed [2*GRAD_W-1:0] ixiy
);

    assign ix2 = ix * ix;
    assign iy2 = iy * iy;
    assign ixiy = ix * iy;

endmodule