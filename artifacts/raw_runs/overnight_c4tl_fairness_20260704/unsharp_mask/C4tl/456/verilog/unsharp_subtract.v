`timescale 1ns/1ps

module unsharp_subtract #(
    parameter PIXEL_W = 8,
    parameter SIGNED_W = PIXEL_W + 16
) (
    input [PIXEL_W-1:0] orig_px,
    input [PIXEL_W-1:0] blur_px,
    output signed [SIGNED_W-1:0] high_freq
);
    assign high_freq = $signed({1'b0, orig_px}) - $signed({1'b0, blur_px});
endmodule