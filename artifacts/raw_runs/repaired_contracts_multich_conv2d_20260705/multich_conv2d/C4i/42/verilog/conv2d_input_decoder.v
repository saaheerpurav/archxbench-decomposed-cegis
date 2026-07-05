`timescale 1ns/1ps

module conv2d_input_decoder #(
    parameter CIN = 3,
    parameter H = 64,
    parameter W = 64
)(
    input  [31:0] flat_index,
    output [31:0] chan,
    output [31:0] row,
    output [31:0] col
);

    localparam integer PLANE_SIZE = H * W;

    wire [31:0] plane_offset;

    assign chan = flat_index / PLANE_SIZE;
    assign plane_offset = flat_index % PLANE_SIZE;

    assign row = plane_offset / W;
    assign col = plane_offset % W;

endmodule