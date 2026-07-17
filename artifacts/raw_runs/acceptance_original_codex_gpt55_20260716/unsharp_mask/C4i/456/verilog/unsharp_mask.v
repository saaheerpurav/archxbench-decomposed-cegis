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

  reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
  reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

  reg [PIXEL_W-1:0] row0_d1, row0_d2;
  reg [PIXEL_W-1:0] row1_d1, row1_d2;
  reg [PIXEL_W-1:0] cur_d1,  cur_d2;

  reg [31:0] x;
  reg [31:0] y;

  integer i;

  wire [PIXEL_W-1:0] line0_cur = line0[x];
  wire [PIXEL_W-1:0] line1_cur = line1[x];

  wire [PIXEL_W-1:0] w00, w01, w02;
  wire [PIXEL_W-1:0] w10, w11, w12;
  wire [PIXEL_W-1:0] w20, w21, w22;

  unsharp_window3x3 #(
    .IMG_WIDTH(IMG_WIDTH),
    .IMG_HEIGHT(IMG_HEIGHT),
    .PIXEL_W(PIXEL_W)
  ) u_window (
    .x(x),
    .y(y),
    .row0_d2(row1_d2),
    .row0_d1(row1_d1),
    .row0_cur(line1_cur),
    .row1_d2(row0_d2),
    .row1_d1(row0_d1),
    .row1_cur(line0_cur),
    .row2_d2(cur_d2),
    .row2_d1(cur_d1),
    .row2_cur(pixel_in),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22)
  );

  wire [PIXEL_W-1:0] blurred;

  unsharp_gaussian3x3 #(
    .PIXEL_W(PIXEL_W)
  ) u_blur (
    .p00(w00), .p01(w01), .p02(w02),
    .p10(w10), .p11(w11), .p12(w12),
    .p20(w20), .p21(w21), .p22(w22),
    .blurred(blurred)
  );

  wire signed [PIXEL_W:0] high_freq;

  unsharp_difference #(
    .PIXEL_W(PIXEL_W)
  ) u_difference (
    .original(pixel_in),
    .blurred(blurred),
    .diff(high_freq)
  );

  wire signed [PIXEL_W+GAIN_W:0] scaled_detail;

  unsharp_gain #(
    .PIXEL_W(PIXEL_W),
    .GAIN_W(GAIN_W)
  ) u_gain (
    .diff(high_freq),
    .gain(gain),
    .scaled(scaled_detail)
  );

  unsharp_reconstruct #(
    .PIXEL_W(PIXEL_W),
    .GAIN_W(GAIN_W)
  ) u_reconstruct (
    .original(pixel_in),
    .scaled(scaled_detail),
    .pixel_out(pixel_out)
  );

  assign valid_out = valid_in;

  always @(posedge clk) begin
    if (rst) begin
      x <= 0;
      y <= 0;
      row0_d1 <= 0;
      row0_d2 <= 0;
      row1_d1 <= 0;
      row1_d2 <= 0;
      cur_d1 <= 0;
      cur_d2 <= 0;
      for (i = 0; i < IMG_WIDTH; i = i + 1) begin
        line0[i] <= 0;
        line1[i] <= 0;
      end
    end else if (valid_in) begin
      line1[x] <= line0[x];
      line0[x] <= pixel_in;

      row1_d2 <= row1_d1;
      row1_d1 <= line1[x];

      row0_d2 <= row0_d1;
      row0_d1 <= line0[x];

      cur_d2 <= cur_d1;
      cur_d1 <= pixel_in;

      if (x == IMG_WIDTH-1) begin
        x <= 0;
        if (y == IMG_HEIGHT-1)
          y <= 0;
        else
          y <= y + 1;

        row0_d1 <= 0;
        row0_d2 <= 0;
        row1_d1 <= 0;
        row1_d2 <= 0;
        cur_d1 <= 0;
        cur_d2 <= 0;
      end else begin
        x <= x + 1;
      end
    end
  end

endmodule