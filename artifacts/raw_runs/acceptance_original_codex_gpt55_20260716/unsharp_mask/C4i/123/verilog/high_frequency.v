`timescale 1ns/1ps

module high_frequency #(
    parameter PIXEL_W = 8,
    parameter DIFF_W = PIXEL_W + 2
) (
    input  [PIXEL_W-1:0] original,
    input  [PIXEL_W-1:0] blurred,
    output signed [DIFF_W-1:0] diff
);

    assign diff =
        $signed({{(DIFF_W-PIXEL_W){1'b0}}, original}) -
        $signed({{(DIFF_W-PIXEL_W){1'b0}}, blurred});

endmodule