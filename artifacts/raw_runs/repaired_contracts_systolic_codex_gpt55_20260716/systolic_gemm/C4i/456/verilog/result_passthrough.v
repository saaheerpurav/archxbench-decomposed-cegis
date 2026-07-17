`timescale 1ns/1ps

module result_passthrough(
    in0, in1, in2, in3,
    in4, in5, in6, in7,
    in8, in9, in10, in11,
    in12, in13, in14, in15,
    out0, out1, out2, out3,
    out4, out5, out6, out7,
    out8, out9, out10, out11,
    out12, out13, out14, out15
);
    input [63:0] in0, in1, in2, in3;
    input [63:0] in4, in5, in6, in7;
    input [63:0] in8, in9, in10, in11;
    input [63:0] in12, in13, in14, in15;

    output [63:0] out0, out1, out2, out3;
    output [63:0] out4, out5, out6, out7;
    output [63:0] out8, out9, out10, out11;
    output [63:0] out12, out13, out14, out15;

    assign out0  = in0;
    assign out1  = in1;
    assign out2  = in2;
    assign out3  = in3;
    assign out4  = in4;
    assign out5  = in5;
    assign out6  = in6;
    assign out7  = in7;
    assign out8  = in8;
    assign out9  = in9;
    assign out10 = in10;
    assign out11 = in11;
    assign out12 = in12;
    assign out13 = in13;
    assign out14 = in14;
    assign out15 = in15;
endmodule