`timescale 1ns/1ps

module conv2d_coord #(
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input  [31:0] col_count,
    input  [31:0] row_count,
    output        at_last_col,
    output        window_valid
);
    assign at_last_col = (col_count == IMG_WIDTH-1);
    assign window_valid = (row_count >= KERNEL_SIZE-1) &&
                          (col_count >= KERNEL_SIZE-1);
endmodule