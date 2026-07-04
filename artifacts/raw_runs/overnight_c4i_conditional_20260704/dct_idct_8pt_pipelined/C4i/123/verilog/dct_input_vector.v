`timescale 1ns/1ps

module dct_input_vector #(
    parameter DATA_W = 12
) (
    input  signed [DATA_W-1:0] x0,
    input  signed [DATA_W-1:0] x1,
    input  signed [DATA_W-1:0] x2,
    input  signed [DATA_W-1:0] x3,
    input  signed [DATA_W-1:0] x4,
    input  signed [DATA_W-1:0] x5,
    input  signed [DATA_W-1:0] x6,
    input  signed [DATA_W-1:0] x7,
    output signed [DATA_W-1:0] s0,
    output signed [DATA_W-1:0] s1,
    output signed [DATA_W-1:0] s2,
    output signed [DATA_W-1:0] s3,
    output signed [DATA_W-1:0] s4,
    output signed [DATA_W-1:0] s5,
    output signed [DATA_W-1:0] s6,
    output signed [DATA_W-1:0] s7
);

    assign s0 = x0;
    assign s1 = x1;
    assign s2 = x2;
    assign s3 = x3;
    assign s4 = x4;
    assign s5 = x5;
    assign s6 = x6;
    assign s7 = x7;

endmodule