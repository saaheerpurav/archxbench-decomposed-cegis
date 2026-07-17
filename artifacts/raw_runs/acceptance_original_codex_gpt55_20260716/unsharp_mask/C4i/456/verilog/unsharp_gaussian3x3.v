`timescale 1ns/1ps

module unsharp_gaussian3x3 #(
    parameter PIXEL_W = 8
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
    output [PIXEL_W-1:0] blurred
);

  localparam SUM_W = PIXEL_W + 4;

  wire [SUM_W-1:0] w00 = {{(SUM_W-PIXEL_W){1'b0}}, p00};
  wire [SUM_W-1:0] w01 = {{(SUM_W-PIXEL_W){1'b0}}, p01};
  wire [SUM_W-1:0] w02 = {{(SUM_W-PIXEL_W){1'b0}}, p02};
  wire [SUM_W-1:0] w10 = {{(SUM_W-PIXEL_W){1'b0}}, p10};
  wire [SUM_W-1:0] w11 = {{(SUM_W-PIXEL_W){1'b0}}, p11};
  wire [SUM_W-1:0] w12 = {{(SUM_W-PIXEL_W){1'b0}}, p12};
  wire [SUM_W-1:0] w20 = {{(SUM_W-PIXEL_W){1'b0}}, p20};
  wire [SUM_W-1:0] w21 = {{(SUM_W-PIXEL_W){1'b0}}, p21};
  wire [SUM_W-1:0] w22 = {{(SUM_W-PIXEL_W){1'b0}}, p22};

  wire [SUM_W-1:0] sum;

  assign sum =
      w00 + (w01 << 1) + w02 +
      (w10 << 1) + (w11 << 2) + (w12 << 1) +
      w20 + (w21 << 1) + w22;

  assign blurred = sum[SUM_W-1:4];

endmodule