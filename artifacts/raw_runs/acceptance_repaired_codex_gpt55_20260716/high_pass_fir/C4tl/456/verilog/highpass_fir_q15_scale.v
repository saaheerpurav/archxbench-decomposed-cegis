`timescale 1ns/1ps

module highpass_fir_q15_scale #(
    parameter ACC_W = 64,
    parameter OUT_W = 24
) (
    input  signed [ACC_W-1:0] accum,
    output signed [OUT_W-1:0] data_out
);
    assign data_out = accum >>> 15;
endmodule