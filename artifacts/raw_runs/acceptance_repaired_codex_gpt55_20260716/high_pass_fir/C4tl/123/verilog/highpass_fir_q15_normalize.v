`timescale 1ns/1ps

module highpass_fir_q15_normalize #(
    parameter ACC_W = 64,
    parameter OUT_W = 24
) (
    input  signed [ACC_W-1:0] acc_sum,
    output signed [ACC_W-1:0] data_out
);
    assign data_out = acc_sum >>> 15;
endmodule