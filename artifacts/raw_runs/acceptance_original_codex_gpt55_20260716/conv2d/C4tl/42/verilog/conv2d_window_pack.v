`timescale 1ns/1ps

module conv2d_window_pack #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] window_in,
    output [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] window_out
);
    assign window_out = window_in;
endmodule