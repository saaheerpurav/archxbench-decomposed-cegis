`timescale 1ns/1ps

module conv3d_coord_decode #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter ADDR_W = 16
) (
    input  [ADDR_W-1:0] index,
    output [ADDR_W-1:0] z_pos,
    output [ADDR_W-1:0] y_pos,
    output [ADDR_W-1:0] x_pos,
    output window_valid
);

    localparam integer FRAME_SIZE = H * W;

    wire [ADDR_W-1:0] frame_offset;

    assign z_pos = index / FRAME_SIZE;
    assign frame_offset = index % FRAME_SIZE;
    assign y_pos = frame_offset / W;
    assign x_pos = frame_offset % W;

    assign window_valid =
        (z_pos >= (K1 - 1)) &&
        (y_pos >= (K2 - 1)) &&
        (x_pos >= (K3 - 1)) &&
        (z_pos < D) &&
        (y_pos < H) &&
        (x_pos < W);

endmodule