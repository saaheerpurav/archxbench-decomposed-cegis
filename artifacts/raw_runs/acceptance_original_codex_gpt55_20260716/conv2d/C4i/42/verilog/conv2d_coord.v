`timescale 1ns/1ps

module conv2d_coord #(
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3
) (
    input      [31:0] row_cnt,
    input      [31:0] col_cnt,
    input             valid_in,
    output            at_left,
    output            at_top,
    output            window_valid
);

    localparam integer PAD = (KERNEL_SIZE - 1) / 2;

    assign at_left = (col_cnt < PAD);
    assign at_top  = (row_cnt < PAD);

    assign window_valid = 1'b1;

endmodule