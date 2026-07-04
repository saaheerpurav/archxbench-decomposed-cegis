`timescale 1ns/1ps

module conv2d_line_address #(
    parameter IMG_WIDTH = 64
) (
    input      [31:0] index,
    output     [31:0] row,
    output     [31:0] col
);
    assign row = index / IMG_WIDTH;
    assign col = index % IMG_WIDTH;

endmodule