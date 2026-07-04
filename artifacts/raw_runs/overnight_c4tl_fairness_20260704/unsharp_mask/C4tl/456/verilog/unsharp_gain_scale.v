`timescale 1ns/1ps

module unsharp_gain_scale #(
    parameter GAIN_W = 8,
    parameter SIGNED_W = 24
) (
    input signed [SIGNED_W-1:0] high_freq,
    input [GAIN_W-1:0] gain,
    output signed [SIGNED_W-1:0] scaled_high
);
    assign scaled_high = high_freq * $signed({1'b0, gain});
endmodule