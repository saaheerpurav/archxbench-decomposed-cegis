`timescale 1ns/1ps

module sharpen_reconstruct #(
    parameter PIXEL_W = 8,
    parameter SCALE_W = 22,
    parameter RECON_W = SCALE_W + 1
) (
    input  [PIXEL_W-1:0]        original,
    input  signed [SCALE_W-1:0] scaled,
    output signed [RECON_W-1:0] reconstructed
);

  assign reconstructed = $signed({1'b0, original}) + scaled;

endmodule