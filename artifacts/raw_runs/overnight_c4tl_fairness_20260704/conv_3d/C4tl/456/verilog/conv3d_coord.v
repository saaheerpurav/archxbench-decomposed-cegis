`timescale 1ns/1ps

module conv3d_coord #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input [31:0] index,
    output [31:0] z,
    output [31:0] y,
    output [31:0] x
);
    assign z = index / (H * W);
    assign y = (index / W) % H;
    assign x = index % W;
endmodule