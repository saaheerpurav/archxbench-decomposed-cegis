`timescale 1ns/1ps

module multich_conv2d_index_decode #(
    parameter COUT = 8,
    parameter OUT_H = 62,
    parameter OUT_WID = 62,
    parameter OUT_CNT_W = 16,
    parameter COUT_W = 4,
    parameter ROW_W = 6,
    parameter COL_W = 6
)(
    input  [OUT_CNT_W-1:0] out_index,
    output reg [COUT_W-1:0] out_ch,
    output reg [ROW_W-1:0] out_row,
    output reg [COL_W-1:0] out_col
);

  localparam integer SPATIAL_SIZE = OUT_H * OUT_WID;

  reg [OUT_CNT_W-1:0] spatial_index;

  always @* begin
    out_ch = out_index / SPATIAL_SIZE;

    spatial_index = out_index % SPATIAL_SIZE;

    out_row = spatial_index / OUT_WID;
    out_col = spatial_index % OUT_WID;
  end

endmodule