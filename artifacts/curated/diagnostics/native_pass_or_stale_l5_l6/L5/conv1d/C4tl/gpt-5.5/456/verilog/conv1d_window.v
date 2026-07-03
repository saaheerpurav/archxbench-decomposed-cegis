`timescale 1ns/1ps

module conv1d_window #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5
) (
    input  [DATA_W-1:0]               x0,
    input  [DATA_W-1:0]               x1,
    input  [DATA_W-1:0]               x2,
    input  [DATA_W-1:0]               x3,
    input  [DATA_W-1:0]               x4,
    output [DATA_W*KERNEL_SIZE-1:0]   window_flat
);

    assign window_flat[DATA_W*1-1:DATA_W*0] = x0;
    assign window_flat[DATA_W*2-1:DATA_W*1] = x1;
    assign window_flat[DATA_W*3-1:DATA_W*2] = x2;
    assign window_flat[DATA_W*4-1:DATA_W*3] = x3;
    assign window_flat[DATA_W*5-1:DATA_W*4] = x4;

endmodule