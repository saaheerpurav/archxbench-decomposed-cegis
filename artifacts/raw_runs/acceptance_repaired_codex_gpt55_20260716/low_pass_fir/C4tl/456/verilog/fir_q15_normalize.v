`timescale 1ns/1ps

module fir_q15_normalize #(
    parameter ACC_W = 64,
    parameter OUT_W = 24
) (
    input  [ACC_W-1:0] acc_in,
    output [OUT_W-1:0] data_out
);
    wire signed [ACC_W-1:0] signed_acc;
    wire signed [ACC_W-1:0] shifted;

    assign signed_acc = acc_in;
    assign shifted    = signed_acc >>> 15;
    assign data_out   = shifted[OUT_W-1:0];
endmodule