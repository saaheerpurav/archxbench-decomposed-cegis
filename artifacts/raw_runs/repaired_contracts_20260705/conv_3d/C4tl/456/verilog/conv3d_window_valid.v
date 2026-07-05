`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter ADDR_W = 16
) (
    input [ADDR_W-1:0] depth_idx,
    input [ADDR_W-1:0] row_idx,
    input [ADDR_W-1:0] col_idx,
    output valid_window
);

    assign valid_window =
        (depth_idx >= (K1 - 1)) &&
        (row_idx   >= (K2 - 1)) &&
        (col_idx   >= (K3 - 1)) &&
        (depth_idx < D) &&
        (row_idx   < H) &&
        (col_idx   < W);

endmodule