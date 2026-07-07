`timescale 1ns/1ps

module bpf_scale_output #(
    parameter ACC_W = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 15
) (
    input  signed [ACC_W-1:0] acc_sum,
    output signed [OUT_W-1:0] data_out
);
    wire signed [ACC_W-1:0] shifted;

    assign shifted  = acc_sum >>> SHIFT;
    assign data_out = shifted[OUT_W-1:0];

endmodule