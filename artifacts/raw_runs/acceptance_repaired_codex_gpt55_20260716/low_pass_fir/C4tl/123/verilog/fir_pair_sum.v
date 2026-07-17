`timescale 1ns/1ps

module fir_pair_sum #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] a,
    input  signed [DATA_W-1:0] b,
    output signed [DATA_W:0]   sum
);
    assign sum = $signed(a) + $signed(b);
endmodule