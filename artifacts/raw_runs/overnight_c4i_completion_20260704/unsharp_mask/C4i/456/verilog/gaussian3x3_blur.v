`timescale 1ns/1ps

module gaussian3x3_blur #(
    parameter PIXEL_W = 8,
    parameter OUT_W = PIXEL_W + 4
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output [OUT_W-1:0]   blur
);

  localparam SUM_W = PIXEL_W + 4;

  wire [SUM_W-1:0] weighted_sum;

  assign weighted_sum =
      {{(SUM_W-PIXEL_W){1'b0}}, p00} +
      ({{(SUM_W-PIXEL_W){1'b0}}, p01} << 1) +
      {{(SUM_W-PIXEL_W){1'b0}}, p02} +
      ({{(SUM_W-PIXEL_W){1'b0}}, p10} << 1) +
      ({{(SUM_W-PIXEL_W){1'b0}}, p11} << 2) +
      ({{(SUM_W-PIXEL_W){1'b0}}, p12} << 1) +
      {{(SUM_W-PIXEL_W){1'b0}}, p20} +
      ({{(SUM_W-PIXEL_W){1'b0}}, p21} << 1) +
      {{(SUM_W-PIXEL_W){1'b0}}, p22};

  assign blur = weighted_sum >> 4;

endmodule