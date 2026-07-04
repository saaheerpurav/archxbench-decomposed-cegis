`timescale 1ns/1ps

module unsharp_subtract #(
    parameter PIXEL_W = 8,
    parameter DIFF_W = PIXEL_W + 2
) (
    input  [PIXEL_W-1:0] original,
    input  [PIXEL_W-1:0] blurred,
    output signed [DIFF_W-1:0] diff
);

    wire signed [DIFF_W-1:0] original_ext;
    wire signed [DIFF_W-1:0] blurred_ext;

    assign original_ext = $signed({{(DIFF_W-PIXEL_W){1'b0}}, original});
    assign blurred_ext  = $signed({{(DIFF_W-PIXEL_W){1'b0}}, blurred});

    assign diff = original_ext - blurred_ext;

endmodule