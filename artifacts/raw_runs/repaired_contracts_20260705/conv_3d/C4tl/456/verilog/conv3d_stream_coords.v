`timescale 1ns/1ps

module conv3d_stream_coords #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter ADDR_W = 16
) (
    input [ADDR_W-1:0] linear_index,
    output [ADDR_W-1:0] depth_idx,
    output [ADDR_W-1:0] row_idx,
    output [ADDR_W-1:0] col_idx
);

    assign depth_idx = linear_index / (H * W);
    assign row_idx = (linear_index / W) % H;
    assign col_idx = linear_index % W;

endmodule