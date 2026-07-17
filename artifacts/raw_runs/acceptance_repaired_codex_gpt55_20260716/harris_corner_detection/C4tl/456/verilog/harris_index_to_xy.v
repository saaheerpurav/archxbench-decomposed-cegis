`timescale 1ns/1ps

module harris_index_to_xy #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128
) (
    input [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] idx,
    output [$clog2(IMG_WIDTH)-1:0] x,
    output [$clog2(IMG_HEIGHT)-1:0] y
);
    assign x = idx % IMG_WIDTH;
    assign y = idx / IMG_WIDTH;
endmodule