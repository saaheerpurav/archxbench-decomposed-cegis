`timescale 1ns/1ps

module bpf_q15_normalizer #(
    parameter ACC_W = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 15
) (
    input  signed [ACC_W-1:0] acc,
    output signed [OUT_W-1:0] result
);

    wire signed [ACC_W-1:0] shifted;

    assign shifted = acc >>> SHIFT;
    assign result  = shifted[OUT_W-1:0];

endmodule