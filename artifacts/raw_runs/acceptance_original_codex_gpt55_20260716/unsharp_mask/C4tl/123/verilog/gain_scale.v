`timescale 1ns/1ps

module gain_scale #(
    parameter GAIN_W = 8,
    parameter DIFF_W = 20
) (
    input signed [DIFF_W-1:0] diff,
    input [GAIN_W-1:0] gain,
    output signed [DIFF_W+GAIN_W-1:0] scaled
);
    assign scaled = diff * $signed({1'b0, gain});
endmodule