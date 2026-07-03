`timescale 1ns/1ps

module conv1d_window #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] data_in,
    input  [DATA_W-1:0] tap1,
    input  [DATA_W-1:0] tap2,
    input  [DATA_W-1:0] tap3,
    input  [DATA_W-1:0] tap4,
    output [DATA_W-1:0] win0,
    output [DATA_W-1:0] win1,
    output [DATA_W-1:0] win2,
    output [DATA_W-1:0] win3,
    output [DATA_W-1:0] win4
);

    assign win0 = data_in;
    assign win1 = tap1;
    assign win2 = tap2;
    assign win3 = tap3;
    assign win4 = tap4;

endmodule