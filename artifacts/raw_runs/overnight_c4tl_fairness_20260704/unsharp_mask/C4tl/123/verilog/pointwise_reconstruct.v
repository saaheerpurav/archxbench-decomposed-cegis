`timescale 1ns/1ps

module pointwise_reconstruct #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input [PIXEL_W-1:0] original_pixel,
    input signed [PIXEL_W+GAIN_W:0] scaled_high_freq,
    output [PIXEL_W-1:0] pixel_out
);

    localparam signed [PIXEL_W+GAIN_W:0] MAX_PIXEL = (1 << PIXEL_W) - 1;
    localparam signed [PIXEL_W+GAIN_W:0] MIN_PIXEL = 0;

    wire signed [PIXEL_W+GAIN_W:0] reconstructed;

    assign reconstructed = $signed({1'b0, original_pixel}) + scaled_high_freq;

    assign pixel_out = (reconstructed < MIN_PIXEL) ? {PIXEL_W{1'b0}} :
                       (reconstructed > MAX_PIXEL) ? {PIXEL_W{1'b1}} :
                       reconstructed[PIXEL_W-1:0];

endmodule