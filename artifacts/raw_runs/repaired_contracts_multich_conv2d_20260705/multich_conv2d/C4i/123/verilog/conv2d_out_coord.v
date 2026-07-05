`timescale 1ns/1ps

module conv2d_out_coord #(
    parameter COUT = 8,
    parameter OUT_H = 62,
    parameter OUT_WID = 62,
    parameter OUT_IDX_W = 15,
    parameter OC_W = 3,
    parameter ROW_W = 6,
    parameter COL_W = 6
)(
    input  [OUT_IDX_W-1:0] out_index,
    output reg [OC_W-1:0]  out_ch,
    output reg [ROW_W-1:0] out_row,
    output reg [COL_W-1:0] out_col
);

    localparam integer SPATIAL_N = OUT_H * OUT_WID;

    integer spatial_i;
    integer ch_i;
    integer row_i;
    integer col_i;

    always @* begin
        spatial_i = out_index % SPATIAL_N;
        ch_i      = out_index / SPATIAL_N;
        row_i     = spatial_i / OUT_WID;
        col_i     = spatial_i % OUT_WID;

        out_ch  = ch_i[OC_W-1:0];
        out_row = row_i[ROW_W-1:0];
        out_col = col_i[COL_W-1:0];
    end

endmodule