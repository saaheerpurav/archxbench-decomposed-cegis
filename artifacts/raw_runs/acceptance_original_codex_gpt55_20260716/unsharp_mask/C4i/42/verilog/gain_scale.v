`timescale 1ns/1ps

module gain_scale #(
    parameter GAIN_W = 8,
    parameter DIFF_W = 10,
    parameter SCALE_W = DIFF_W + GAIN_W + 1
) (
    input  signed [DIFF_W-1:0]  diff,
    input         [GAIN_W-1:0]  gain,
    output signed [SCALE_W-1:0] scaled
);

    wire signed [GAIN_W:0] gain_signed;

    assign gain_signed = $signed({1'b0, gain});
    assign scaled = diff * gain_signed;

endmodule