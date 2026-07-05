`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3
) (
    input  [31:0] z_pos,
    input  [31:0] y_pos,
    input  [31:0] x_pos,
    output        valid
);

    localparam [31:0] Z_MIN = K1 - 1;
    localparam [31:0] Y_MIN = K2 - 1;
    localparam [31:0] X_MIN = K3 - 1;

    assign valid = (z_pos >= Z_MIN) &&
                   (y_pos >= Y_MIN) &&
                   (x_pos >= X_MIN);

endmodule