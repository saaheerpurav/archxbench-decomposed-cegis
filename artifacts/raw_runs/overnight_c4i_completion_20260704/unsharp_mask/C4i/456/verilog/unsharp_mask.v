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

  localparam BLUR_W  = PIXEL_W + 4;
  localparam DIFF_W  = PIXEL_W + 5;
  localparam SCALE_W = PIXEL_W + GAIN_W + 6;
  localparam RECON_W = PIXEL_W + GAIN_W + 7;

  reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
  reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

  reg [PIXEL_W-1:0] row0_d1, row0_d2;
  reg [PIXEL_W-1:0] row1_d1, row1_d2;
  reg [PIXEL_W-1:0] row2_d1, row2_d2;

  reg [31:0] x_pos;
  reg [31:0] y_pos;

  reg [PIXEL_W-1:0] out_r;
  reg valid_r;

  wire first_col = (x_pos == 0);
  wire second_col = (x_pos == 1);
  wire first_row = (y_pos == 0);
  wire second_row = (y_pos == 1);

  wire [PIXEL_W-1:0] lb0_cur = first_row ? {PIXEL_W{1'b0}} : line0[x_pos];
  wire [PIXEL_W-1:0] lb1_cur = (first_row || second_row) ? {PIXEL_W{1'b0}} : line1[x_pos];

  wire [PIXEL_W-1:0] w00 = (first_row || second_row || first_col || second_col) ? {PIXEL_W{1'b0}} : row2_d2;
  wire [PIXEL_W-1:0] w01 = (first_row || second_row || first_col)              ? {PIXEL_W{1'b0}} : row2_d1;
  wire [PIXEL_W-1:0] w02 = (first_row || second_row)                            ? {PIXEL_W{1'b0}} : lb1_cur;

  wire [PIXEL_W-1:0] w10 = (first_row || first_col || second_col) ? {PIXEL_W{1'b0}} : row1_d2;
  wire [PIXEL_W-1:0] w11 = (first_row || first_col)              ? {PIXEL_W{1'b0}} : row1_d1;
  wire [PIXEL_W-1:0] w12 = first_row                             ? {PIXEL_W{1'b0}} : lb0_cur;

  wire [PIXEL_W-1:0] w20 = (first_col || second_col) ? {PIXEL_W{1'b0}} : row0_d2;
  wire [PIXEL_W-1:0] w21 = first_col                ? {PIXEL_W{1'b0}} : row0_d1;
  wire [PIXEL_W-1:0] w22 = pixel_in;

  wire [BLUR_W-1:0] blur_pixel;
  wire signed [DIFF_W-1:0] high_freq;
  wire signed [SCALE_W-1:0] scaled_high_freq;
  wire signed [RECON_W-1:0] reconstructed;
  wire [PIXEL_W-1:0] clamped_pixel;

  gaussian3x3_blur #(
    .PIXEL_W(PIXEL_W),
    .OUT_W(BLUR_W)
  ) u_blur (
    .p00(w00), .p01(w01), .p02(w02),
    .p10(w10), .p11(w11), .p12(w12),
    .p20(w20), .p21(w21), .p22(w22),
    .blur(blur_pixel)
  );

  high_frequency_subtract #(
    .PIXEL_W(PIXEL_W),
    .BLUR_W(BLUR_W),
    .DIFF_W(DIFF_W)
  ) u_subtract (
    .original(pixel_in),
    .blur(blur_pixel),
    .diff(high_freq)
  );

  gain_scale #(
    .DIFF_W(DIFF_W),
    .GAIN_W(GAIN_W),
    .SCALE_W(SCALE_W)
  ) u_gain (
    .diff(high_freq),
    .gain(gain),
    .scaled(scaled_high_freq)
  );

  sharpen_reconstruct #(
    .PIXEL_W(PIXEL_W),
    .SCALE_W(SCALE_W),
    .RECON_W(RECON_W)
  ) u_reconstruct (
    .original(pixel_in),
    .scaled(scaled_high_freq),
    .reconstructed(reconstructed)
  );

  saturate_pixel #(
    .IN_W(RECON_W),
    .PIXEL_W(PIXEL_W)
  ) u_saturate (
    .value_in(reconstructed),
    .pixel_out(clamped_pixel)
  );

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      x_pos <= 0;
      y_pos <= 0;
      row0_d1 <= 0;
      row0_d2 <= 0;
      row1_d1 <= 0;
      row1_d2 <= 0;
      row2_d1 <= 0;
      row2_d2 <= 0;
      out_r <= 0;
      valid_r <= 0;
      for (i = 0; i < IMG_WIDTH; i = i + 1) begin
        line0[i] <= 0;
        line1[i] <= 0;
      end
    end else begin
      valid_r <= valid_in;

      if (valid_in) begin
        out_r <= clamped_pixel;

        line1[x_pos] <= line0[x_pos];
        line0[x_pos] <= pixel_in;

        row2_d2 <= row2_d1;
        row2_d1 <= lb1_cur;
        row1_d2 <= row1_d1;
        row1_d1 <= lb0_cur;
        row0_d2 <= row0_d1;
        row0_d1 <= pixel_in;

        if (x_pos == IMG_WIDTH-1) begin
          x_pos <= 0;
          if (y_pos == IMG_HEIGHT-1)
            y_pos <= 0;
          else
            y_pos <= y_pos + 1;
        end else begin
          x_pos <= x_pos + 1;
        end
      end
    end
  end

  assign pixel_out = out_r;
  assign valid_out = valid_r;

endmodule