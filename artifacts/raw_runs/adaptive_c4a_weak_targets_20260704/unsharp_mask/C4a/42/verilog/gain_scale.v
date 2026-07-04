`timescale 1ns/1ps

module gain_scale #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input  signed [PIXEL_W:0] high_freq,
    input         [GAIN_W-1:0] gain,
    output signed [PIXEL_W+GAIN_W:0] scaled
);

    wire signed [GAIN_W:0] gain_signed;

    assign gain_signed = $signed({1'b0, gain});
    assign scaled = high_freq * gain_signed;

endmodule