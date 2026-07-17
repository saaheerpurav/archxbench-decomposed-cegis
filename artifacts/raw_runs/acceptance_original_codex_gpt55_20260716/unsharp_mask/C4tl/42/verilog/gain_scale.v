`timescale 1ns/1ps

module gain_scale #(
    parameter GAIN_W = 8,
    parameter DIFF_W = 10,
    parameter PROD_W = DIFF_W + GAIN_W
) (
    input signed [DIFF_W-1:0] high_freq,
    input [GAIN_W-1:0] gain,
    output signed [PROD_W-1:0] scaled_high
);
    assign scaled_high = high_freq * $signed({1'b0, gain});
endmodule