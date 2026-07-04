`timescale 1ns/1ps

module high_freq_sub #(
    parameter PIXEL_W = 8
) (
    input  [PIXEL_W-1:0] original,
    input  [PIXEL_W-1:0] blurred,
    output signed [PIXEL_W:0] high_freq
);

    assign high_freq = $signed({1'b0, original}) - $signed({1'b0, blurred});

endmodule