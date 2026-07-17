`timescale 1ns/1ps

module high_frequency_subtract #(
    parameter PIXEL_W = 8,
    parameter DIFF_W = PIXEL_W + 2
) (
    input [PIXEL_W-1:0] original,
    input [PIXEL_W-1:0] blurred,
    output signed [DIFF_W-1:0] high_freq
);
    assign high_freq =
        $signed({1'b0, original}) -
        $signed({1'b0, blurred});
endmodule