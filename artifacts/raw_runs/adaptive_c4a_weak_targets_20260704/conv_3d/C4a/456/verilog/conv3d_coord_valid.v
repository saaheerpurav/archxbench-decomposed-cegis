`timescale 1ns/1ps

module conv3d_coord_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64
) (
    input  [31:0] x_pos,
    input  [31:0] y_pos,
    input  [31:0] z_pos,
    output        valid_coord
);

    localparam [31:0] X_FIRST = (K3 > 0) ? (K3 - 1) : 0;
    localparam [31:0] Y_FIRST = (K2 > 0) ? (K2 - 1) : 0;
    localparam [31:0] Z_FIRST = (K1 > 0) ? (K1 - 1) : 0;

    localparam [31:0] X_LIMIT = W;
    localparam [31:0] Y_LIMIT = H;
    localparam [31:0] Z_LIMIT = D;

    assign valid_coord =
        (x_pos >= X_FIRST) && (x_pos < X_LIMIT) &&
        (y_pos >= Y_FIRST) && (y_pos < Y_LIMIT) &&
        (z_pos >= Z_FIRST) && (z_pos < Z_LIMIT);

endmodule