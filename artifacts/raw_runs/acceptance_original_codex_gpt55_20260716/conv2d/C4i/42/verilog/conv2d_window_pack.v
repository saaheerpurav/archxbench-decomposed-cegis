`timescale 1ns/1ps

module conv2d_window_pack #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3
) (
    input  [DATA_W-1:0] p00,
    input  [DATA_W-1:0] p01,
    input  [DATA_W-1:0] p02,
    input  [DATA_W-1:0] p10,
    input  [DATA_W-1:0] p11,
    input  [DATA_W-1:0] p12,
    input  [DATA_W-1:0] p20,
    input  [DATA_W-1:0] p21,
    input  [DATA_W-1:0] p22,
    output [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_flat
);

    assign window_flat[DATA_W*1-1:DATA_W*0] = p00;
    assign window_flat[DATA_W*2-1:DATA_W*1] = p01;
    assign window_flat[DATA_W*3-1:DATA_W*2] = p02;

    assign window_flat[DATA_W*4-1:DATA_W*3] = p10;
    assign window_flat[DATA_W*5-1:DATA_W*4] = p11;
    assign window_flat[DATA_W*6-1:DATA_W*5] = p12;

    assign window_flat[DATA_W*7-1:DATA_W*6] = p20;
    assign window_flat[DATA_W*8-1:DATA_W*7] = p21;
    assign window_flat[DATA_W*9-1:DATA_W*8] = p22;

endmodule