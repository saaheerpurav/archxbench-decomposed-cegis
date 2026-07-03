`timescale 1ns/1ps

module conv1d_window #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] data_in,
    input  [DATA_W-1:0] sample_d1,
    input  [DATA_W-1:0] sample_d2,
    input  [DATA_W-1:0] sample_d3,
    input  [DATA_W-1:0] sample_d4,
    output [DATA_W-1:0] tap0,
    output [DATA_W-1:0] tap1,
    output [DATA_W-1:0] tap2,
    output [DATA_W-1:0] tap3,
    output [DATA_W-1:0] tap4
);

    assign tap0 = data_in;
    assign tap1 = sample_d1;
    assign tap2 = sample_d2;
    assign tap3 = sample_d3;
    assign tap4 = sample_d4;

endmodule