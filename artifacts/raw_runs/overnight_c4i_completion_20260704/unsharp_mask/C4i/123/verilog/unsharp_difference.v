`timescale 1ns/1ps

module unsharp_difference #(
    parameter PIXEL_W = 8,
    parameter DIFF_W = PIXEL_W + 2
) (
    input  [PIXEL_W-1:0] original,
    input  [PIXEL_W-1:0] blurred,
    output signed [DIFF_W-1:0] diff
);

    assign diff = $signed({1'b0, original}) - $signed({1'b0, blurred});

endmodule