`timescale 1ns/1ps

module conv2d_window_pack #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3
) (
    input  [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_in_flat,
    output [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_out_flat
);
    assign window_out_flat = window_in_flat;
endmodule