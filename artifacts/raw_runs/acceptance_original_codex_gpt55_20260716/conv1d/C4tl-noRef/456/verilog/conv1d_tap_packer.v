`timescale 1ns/1ps

module conv1d_tap_packer #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5
) (
    input  [DATA_W-1:0]             x0,
    input  [DATA_W-1:0]             x1,
    input  [DATA_W-1:0]             x2,
    input  [DATA_W-1:0]             x3,
    input  [DATA_W-1:0]             x4,
    output [KERNEL_SIZE*DATA_W-1:0] tap_bus
);

    assign tap_bus[DATA_W*1-1:DATA_W*0] = x0;
    assign tap_bus[DATA_W*2-1:DATA_W*1] = x1;
    assign tap_bus[DATA_W*3-1:DATA_W*2] = x2;
    assign tap_bus[DATA_W*4-1:DATA_W*3] = x3;
    assign tap_bus[DATA_W*5-1:DATA_W*4] = x4;

endmodule