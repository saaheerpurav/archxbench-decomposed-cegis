`timescale 1ns/1ps

module conv3d_coord_calc #(
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] linear_index,
    output [31:0] z,
    output [31:0] y,
    output [31:0] x
);

    localparam [31:0] PLANE_SIZE = H * W;

    assign z = linear_index / PLANE_SIZE;
    assign y = (linear_index / W) % H;
    assign x = linear_index % W;

endmodule