`timescale 1ns/1ps

module harris_gaussian_passthrough #(
    parameter PROD_W = 32
) (
    input [PROD_W-1:0] ix2_in,
    input [PROD_W-1:0] iy2_in,
    input signed [PROD_W-1:0] ixiy_in,
    output [PROD_W-1:0] ix2_out,
    output [PROD_W-1:0] iy2_out,
    output signed [PROD_W-1:0] ixiy_out
);

    assign ix2_out = ix2_in;
    assign iy2_out = iy2_in;
    assign ixiy_out = ixiy_in;

endmodule