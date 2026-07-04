`timescale 1ns/1ps

module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter SCALE_W = 19
) (
    input  [PIXEL_W-1:0]        original,
    input  signed [SCALE_W-1:0] scaled_diff,
    output signed [SCALE_W:0]   reconstructed
);

    wire signed [SCALE_W:0] original_ext;
    wire signed [SCALE_W:0] scaled_diff_ext;

    assign original_ext    = {{(SCALE_W + 1 - PIXEL_W){1'b0}}, original};
    assign scaled_diff_ext = {scaled_diff[SCALE_W-1], scaled_diff};

    assign reconstructed = original_ext + scaled_diff_ext;

endmodule