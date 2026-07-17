`timescale 1ns/1ps

module reconstruct_pixel #(
    parameter PIXEL_W = 8,
    parameter IN_W = 28
) (
    input [PIXEL_W-1:0] orig,
    input signed [IN_W-1:0] scaled,
    output signed [IN_W:0] recon
);
    assign recon = $signed({1'b0, orig}) + scaled;
endmodule