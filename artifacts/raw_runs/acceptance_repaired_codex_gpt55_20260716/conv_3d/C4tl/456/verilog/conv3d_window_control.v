`timescale 1ns/1ps

module conv3d_window_control #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter ADDR_W = 15
) (
    input  [ADDR_W-1:0] x_pos,
    input  [ADDR_W-1:0] y_pos,
    input  [ADDR_W-1:0] z_pos,
    output window_valid
);

    localparam HAS_VALID_WINDOWS =
        (D >= K1) && (H >= K2) && (W >= K3);

    assign window_valid =
        HAS_VALID_WINDOWS &&
        (z_pos >= (K1 - 1)) && (z_pos < D) &&
        (y_pos >= (K2 - 1)) && (y_pos < H) &&
        (x_pos >= (K3 - 1)) && (x_pos < W);

endmodule