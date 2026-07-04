`timescale 1ns/1ps

module pointwise_gain #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input signed [PIXEL_W:0] high_freq,
    input [GAIN_W-1:0] gain,
    output signed [PIXEL_W+GAIN_W:0] scaled_high_freq
);

    assign scaled_high_freq = high_freq * $signed({1'b0, gain});

endmodule