`timescale 1ns/1ps

module conv2d_coord #(
    parameter IMG_WIDTH = 64
) (
    input  [31:0] col_count,
    output [31:0] next_col,
    output        end_of_line
);
    assign end_of_line = (col_count == IMG_WIDTH-1);
    assign next_col = end_of_line ? 32'd0 : (col_count + 32'd1);
endmodule