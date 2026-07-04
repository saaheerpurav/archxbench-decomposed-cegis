`timescale 1ns/1ps

module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter SCALE_W = 18
) (
    input  [PIXEL_W-1:0]          original,
    input  signed [SCALE_W-1:0]   scaled_difference,
    output [PIXEL_W-1:0]          pixel_out
);

  localparam RESULT_W = (SCALE_W > PIXEL_W) ? (SCALE_W + 1) : (PIXEL_W + 1);

  wire signed [RESULT_W-1:0] original_ext;
  wire signed [RESULT_W-1:0] scaled_ext;
  wire signed [RESULT_W-1:0] result;
  wire signed [RESULT_W-1:0] max_pixel;

  assign original_ext = $signed({{(RESULT_W-PIXEL_W){1'b0}}, original});
  assign scaled_ext   = {{(RESULT_W-SCALE_W){scaled_difference[SCALE_W-1]}}, scaled_difference};

  assign result = original_ext + scaled_ext;

  assign max_pixel = $signed({{(RESULT_W-PIXEL_W){1'b0}}, {PIXEL_W{1'b1}}});

  assign pixel_out =
      (result < 0)         ? {PIXEL_W{1'b0}} :
      (result > max_pixel) ? {PIXEL_W{1'b1}} :
                             result[PIXEL_W-1:0];

endmodule