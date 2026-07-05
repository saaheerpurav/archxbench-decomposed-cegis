`timescale 1ns/1ps

module conv2d_addr_gen #(
    parameter CIN = 3,
    parameter H = 64,
    parameter W = 64,
    parameter K = 3
)(
    input  [31:0] channel,
    input  [31:0] row,
    input  [31:0] col,
    input  [31:0] krow,
    input  [31:0] kcol,
    output [31:0] addr
);

    localparam [31:0] CHANNEL_STRIDE = H * W;

    wire [31:0] abs_row;
    wire [31:0] abs_col;
    wire [31:0] channel_base;
    wire [31:0] row_base;

    assign abs_row = row + krow;
    assign abs_col = col + kcol;

    assign channel_base = channel * CHANNEL_STRIDE;
    assign row_base     = abs_row * W;

    assign addr = channel_base + row_base + abs_col;

endmodule