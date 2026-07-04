`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64
) (
    input  [31:0] z,
    input  [31:0] y,
    input  [31:0] x,
    output        valid
);

    localparam [31:0] Z_MIN = (K1 > 0) ? (K1 - 1) : 0;
    localparam [31:0] Y_MIN = (K2 > 0) ? (K2 - 1) : 0;
    localparam [31:0] X_MIN = (K3 > 0) ? (K3 - 1) : 0;

    localparam DIMS_VALID = (K1 > 0) && (K2 > 0) && (K3 > 0) &&
                            (D >= K1) && (H >= K2) && (W >= K3);

    assign valid = DIMS_VALID &&
                   (z >= Z_MIN) && (z < D) &&
                   (y >= Y_MIN) && (y < H) &&
                   (x >= X_MIN) && (x < W);

endmodule