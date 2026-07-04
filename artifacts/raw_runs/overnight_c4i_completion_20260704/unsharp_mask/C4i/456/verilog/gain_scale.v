`timescale 1ns/1ps

module gain_scale #(
    parameter DIFF_W = 13,
    parameter GAIN_W = 8,
    parameter SCALE_W = DIFF_W + GAIN_W + 1
) (
    input  signed [DIFF_W-1:0]  diff,
    input         [GAIN_W-1:0]  gain,
    output signed [SCALE_W-1:0] scaled
);

  wire signed [SCALE_W-1:0] diff_ext;
  wire signed [SCALE_W-1:0] gain_ext;

  assign diff_ext = {{(SCALE_W-DIFF_W){diff[DIFF_W-1]}}, diff};
  assign gain_ext = {{(SCALE_W-GAIN_W){1'b0}}, gain};

  assign scaled = diff_ext * gain_ext;

endmodule