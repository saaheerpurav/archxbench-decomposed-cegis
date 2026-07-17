`timescale 1ns/1ps

module conv2d_window_valid #(
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input      [15:0] row,
    input      [15:0] col,
    input             valid_in,
    output            valid_out
);

    assign valid_out = valid_in;

endmodule