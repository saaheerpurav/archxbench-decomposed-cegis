`timescale 1ns/1ps

module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

  localparam DIFF_W  = PIXEL_W + 2;
  localparam SCALE_W = PIXEL_W + GAIN_W + 2;

  reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
  reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

  reg [PIXEL_W-1:0] cur_m1, cur_m2;
  reg [PIXEL_W-1:0] row1_m1, row1_m2;
  reg [PIXEL_W-1:0] row2_m1, row2_m2;

  reg [PIXEL_W-1:0] w00, w01, w02;
  reg [PIXEL_W-1:0] w10, w11, w12;
  reg [PIXEL_W-1:0] w20, w21, w22;

  reg [PIXEL_W-1:0] orig_r;
  reg valid_r;

  reg [15:0] col;
  reg [15:0] row;

  wire [PIXEL_W-1:0] row1_cur = (row == 0) ? {PIXEL_W{1'b0}} : line0[col];
  wire [PIXEL_W-1:0] row2_cur = (row < 2)  ? {PIXEL_W{1'b0}} : line1[col];

  wire [PIXEL_W-1:0] blur_w;
  wire signed [DIFF_W-1:0] diff_w;
  wire signed [SCALE_W-1:0] scaled_w;
  wire [PIXEL_W-1:0] sharp_w;

  gaussian3x3_blur #(
    .PIXEL_W(PIXEL_W)
  ) u_blur (
    .p00(w00), .p01(w01), .p02(w02),
    .p10(w10), .p11(w11), .p12(w12),
    .p20(w20), .p21(w21), .p22(w22),
    .blur(blur_w)
  );

  unsharp_difference #(
    .PIXEL_W(PIXEL_W),
    .DIFF_W(DIFF_W)
  ) u_diff (
    .original(orig_r),
    .blurred(blur_w),
    .difference(diff_w)
  );

  unsharp_gain #(
    .GAIN_W(GAIN_W),
    .DIFF_W(DIFF_W),
    .SCALE_W(SCALE_W)
  ) u_gain (
    .difference(diff_w),
    .gain(gain),
    .scaled_difference(scaled_w)
  );

  unsharp_reconstruct #(
    .PIXEL_W(PIXEL_W),
    .SCALE_W(SCALE_W)
  ) u_reconstruct (
    .original(orig_r),
    .scaled_difference(scaled_w),
    .pixel_out(sharp_w)
  );

  integer i;

  always @(posedge clk) begin
    if (rst) begin
      col <= 0;
      row <= 0;
      cur_m1 <= 0;
      cur_m2 <= 0;
      row1_m1 <= 0;
      row1_m2 <= 0;
      row2_m1 <= 0;
      row2_m2 <= 0;
      w00 <= 0; w01 <= 0; w02 <= 0;
      w10 <= 0; w11 <= 0; w12 <= 0;
      w20 <= 0; w21 <= 0; w22 <= 0;
      orig_r <= 0;
      valid_r <= 0;
      for (i = 0; i < IMG_WIDTH; i = i + 1) begin
        line0[i] <= 0;
        line1[i] <= 0;
      end
    end else begin
      valid_r <= valid_in;

      if (valid_in) begin
        w00 <= row2_m2;
        w01 <= row2_m1;
        w02 <= row2_cur;
        w10 <= row1_m2;
        w11 <= row1_m1;
        w12 <= row1_cur;
        w20 <= cur_m2;
        w21 <= cur_m1;
        w22 <= pixel_in;

        orig_r <= pixel_in;

        line1[col] <= row1_cur;
        line0[col] <= pixel_in;

        if (col == IMG_WIDTH-1) begin
          col <= 0;
          row <= (row == IMG_HEIGHT-1) ? 0 : row + 1'b1;
          cur_m1 <= 0;
          cur_m2 <= 0;
          row1_m1 <= 0;
          row1_m2 <= 0;
          row2_m1 <= 0;
          row2_m2 <= 0;
        end else begin
          col <= col + 1'b1;
          cur_m2 <= cur_m1;
          cur_m1 <= pixel_in;
          row1_m2 <= row1_m1;
          row1_m1 <= row1_cur;
          row2_m2 <= row2_m1;
          row2_m1 <= row2_cur;
        end
      end
    end
  end

  assign pixel_out = sharp_w;
  assign valid_out = valid_r;

endmodule