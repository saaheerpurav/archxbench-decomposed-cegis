`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W = 32,
    parameter OUT_W = 36
) (
    input [IN_W-1:0] ix2_00,
    input [IN_W-1:0] ix2_01,
    input [IN_W-1:0] ix2_02,
    input [IN_W-1:0] ix2_10,
    input [IN_W-1:0] ix2_11,
    input [IN_W-1:0] ix2_12,
    input [IN_W-1:0] ix2_20,
    input [IN_W-1:0] ix2_21,
    input [IN_W-1:0] ix2_22,

    input [IN_W-1:0] iy2_00,
    input [IN_W-1:0] iy2_01,
    input [IN_W-1:0] iy2_02,
    input [IN_W-1:0] iy2_10,
    input [IN_W-1:0] iy2_11,
    input [IN_W-1:0] iy2_12,
    input [IN_W-1:0] iy2_20,
    input [IN_W-1:0] iy2_21,
    input [IN_W-1:0] iy2_22,

    input signed [IN_W-1:0] ixy_00,
    input signed [IN_W-1:0] ixy_01,
    input signed [IN_W-1:0] ixy_02,
    input signed [IN_W-1:0] ixy_10,
    input signed [IN_W-1:0] ixy_11,
    input signed [IN_W-1:0] ixy_12,
    input signed [IN_W-1:0] ixy_20,
    input signed [IN_W-1:0] ixy_21,
    input signed [IN_W-1:0] ixy_22,

    output [OUT_W-1:0] smooth_ix2,
    output [OUT_W-1:0] smooth_iy2,
    output signed [OUT_W-1:0] smooth_ixy
);

    assign smooth_ix2 =
        ix2_00 + (ix2_01 << 1) + ix2_02 +
        (ix2_10 << 1) + (ix2_11 << 2) + (ix2_12 << 1) +
        ix2_20 + (ix2_21 << 1) + ix2_22;

    assign smooth_iy2 =
        iy2_00 + (iy2_01 << 1) + iy2_02 +
        (iy2_10 << 1) + (iy2_11 << 2) + (iy2_12 << 1) +
        iy2_20 + (iy2_21 << 1) + iy2_22;

    assign smooth_ixy =
        ixy_00 + (ixy_01 <<< 1) + ixy_02 +
        (ixy_10 <<< 1) + (ixy_11 <<< 2) + (ixy_12 <<< 1) +
        ixy_20 + (ixy_21 <<< 1) + ixy_22;

endmodule