`timescale 1ns/1ps

module multich_conv2d_window_mac #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter MAC_W = 24,
    parameter IMG_BITS = CIN*H*W*DATA_W,
    parameter COUT_W = 4,
    parameter ROW_W = 6,
    parameter COL_W = 6
)(
    input [IMG_BITS-1:0] image_flat,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [COUT_W-1:0] out_ch,
    input [ROW_W-1:0] out_row,
    input [COL_W-1:0] out_col,
    output reg [MAC_W-1:0] mac_out
);

  integer ic;
  integer kr;
  integer kc;
  integer image_index;
  integer kernel_index;

  reg [DATA_W-1:0] pixel_value;
  reg [DATA_W-1:0] kernel_value;
  reg [(2*DATA_W)-1:0] product_value;

  always @* begin
    mac_out = {MAC_W{1'b0}};

    for (ic = 0; ic < CIN; ic = ic + 1) begin
      for (kr = 0; kr < K; kr = kr + 1) begin
        for (kc = 0; kc < K; kc = kc + 1) begin
          image_index = ((ic * H + (out_row + kr)) * W + (out_col + kc));
          kernel_index = (((out_ch * CIN + ic) * K + kr) * K + kc);

          pixel_value = image_flat[image_index*DATA_W +: DATA_W];
          kernel_value = kernel[kernel_index*DATA_W +: DATA_W];

          product_value = pixel_value * kernel_value;
          mac_out = mac_out + {{(MAC_W-(2*DATA_W)){1'b0}}, product_value};
        end
      end
    end
  end

endmodule