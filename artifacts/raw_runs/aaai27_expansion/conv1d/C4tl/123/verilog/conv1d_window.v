`timescale 1ns/1ps

module conv1d_window #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] data_in,
    input  [DATA_W-1:0] delay_1,
    input  [DATA_W-1:0] delay_2,
    input  [DATA_W-1:0] delay_3,
    input  [DATA_W-1:0] delay_4,
    output [DATA_W-1:0] tap0,
    output [DATA_W-1:0] tap1,
    output [DATA_W-1:0] tap2,
    output [DATA_W-1:0] tap3,
    output [DATA_W-1:0] tap4
);

    assign tap0 = data_in;
    assign tap1 = delay_1;
    assign tap2 = delay_2;
    assign tap3 = delay_3;
    assign tap4 = delay_4;

endmodule