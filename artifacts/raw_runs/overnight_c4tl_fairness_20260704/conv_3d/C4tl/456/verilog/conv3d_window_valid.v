`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input [31:0] z,
    input [31:0] y,
    input [31:0] x,
    output valid
);
    assign valid = (z >= (K1 - 1)) &&
                   (y >= (K2 - 1)) &&
                   (x >= (K3 - 1)) &&
                   (z < D) &&
                   (y < H) &&
                   (x < W);
endmodule