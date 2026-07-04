`timescale 1ns/1ps

module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter SIGNED_W = PIXEL_W + 16
) (
    input [PIXEL_W-1:0] orig_px,
    input signed [SIGNED_W-1:0] scaled_high,
    output signed [SIGNED_W-1:0] recon_value
);
    assign recon_value = $signed({1'b0, orig_px}) + scaled_high;
endmodule