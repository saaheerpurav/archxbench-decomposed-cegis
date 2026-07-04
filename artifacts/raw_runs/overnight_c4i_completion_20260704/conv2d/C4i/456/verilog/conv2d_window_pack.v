`timescale 1ns/1ps

module conv2d_window_pack #(
    parameter DATA_W = 8,
    parameter KERNEL_SIZE = 3
) (
    input  [DATA_W-1:0] w00, input [DATA_W-1:0] w01, input [DATA_W-1:0] w02,
    input  [DATA_W-1:0] w10, input [DATA_W-1:0] w11, input [DATA_W-1:0] w12,
    input  [DATA_W-1:0] w20, input [DATA_W-1:0] w21, input [DATA_W-1:0] w22,
    output [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] flat_window
);

    assign flat_window[0*DATA_W +: DATA_W] = w00;
    assign flat_window[1*DATA_W +: DATA_W] = w01;
    assign flat_window[2*DATA_W +: DATA_W] = w02;
    assign flat_window[3*DATA_W +: DATA_W] = w10;
    assign flat_window[4*DATA_W +: DATA_W] = w11;
    assign flat_window[5*DATA_W +: DATA_W] = w12;
    assign flat_window[6*DATA_W +: DATA_W] = w20;
    assign flat_window[7*DATA_W +: DATA_W] = w21;
    assign flat_window[8*DATA_W +: DATA_W] = w22;

endmodule