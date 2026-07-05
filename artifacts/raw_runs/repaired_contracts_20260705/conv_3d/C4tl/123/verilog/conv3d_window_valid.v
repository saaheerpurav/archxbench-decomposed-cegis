`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3
) (
    input  [31:0] depth_idx,
    input  [31:0] row_idx,
    input  [31:0] col_idx,
    output        valid
);

    localparam [31:0] DEPTH_MIN = K1 - 1;
    localparam [31:0] ROW_MIN   = K2 - 1;
    localparam [31:0] COL_MIN   = K3 - 1;

    assign valid = (depth_idx >= DEPTH_MIN) &&
                   (row_idx   >= ROW_MIN)   &&
                   (col_idx   >= COL_MIN);

endmodule