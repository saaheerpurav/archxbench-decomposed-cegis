`timescale 1ns/1ps

module conv2d_valid_region #(
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input             valid_in,
    input      [31:0] row_count,
    input      [31:0] col_count,
    output            window_valid
);
    assign window_valid = valid_in &&
                          (row_count >= KERNEL_SIZE-1) &&
                          (col_count >= KERNEL_SIZE-1) &&
                          (col_count < IMG_WIDTH);
endmodule