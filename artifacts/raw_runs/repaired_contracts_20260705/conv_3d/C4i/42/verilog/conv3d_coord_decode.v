`timescale 1ns/1ps

module conv3d_coord_decode #(
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] linear_idx,
    output [31:0] z_pos,
    output [31:0] y_pos,
    output [31:0] x_pos
);

    localparam [31:0] FRAME_SIZE = H * W;

    wire [31:0] frame_offset;

    assign z_pos        = linear_idx / FRAME_SIZE;
    assign frame_offset = linear_idx % FRAME_SIZE;
    assign y_pos        = frame_offset / W;
    assign x_pos        = frame_offset % W;

endmodule