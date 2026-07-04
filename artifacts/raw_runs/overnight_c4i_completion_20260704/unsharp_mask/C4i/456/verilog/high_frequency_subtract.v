`timescale 1ns/1ps

module high_frequency_subtract #(
    parameter PIXEL_W = 8,
    parameter BLUR_W  = PIXEL_W + 4,
    parameter DIFF_W  = PIXEL_W + 5
) (
    input  [PIXEL_W-1:0]        original,
    input  [BLUR_W-1:0]         blur,
    output signed [DIFF_W-1:0]  diff
);

  assign diff =
      $signed({{(DIFF_W-PIXEL_W){1'b0}}, original}) -
      $signed({{(DIFF_W-BLUR_W){1'b0}},  blur});

endmodule