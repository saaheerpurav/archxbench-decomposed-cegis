`timescale 1ns/1ps

module conv1d_tap_shift #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] sample_in,
    input  [DATA_W-1:0] tap1_in,
    input  [DATA_W-1:0] tap2_in,
    input  [DATA_W-1:0] tap3_in,
    output [DATA_W-1:0] tap1_out,
    output [DATA_W-1:0] tap2_out,
    output [DATA_W-1:0] tap3_out,
    output [DATA_W-1:0] tap4_out
);

    assign tap1_out = sample_in;
    assign tap2_out = tap1_in;
    assign tap3_out = tap2_in;
    assign tap4_out = tap3_in;

endmodule