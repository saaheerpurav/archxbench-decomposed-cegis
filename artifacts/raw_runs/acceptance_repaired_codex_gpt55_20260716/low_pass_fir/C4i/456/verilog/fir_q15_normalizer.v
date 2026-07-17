`timescale 1ns/1ps

module fir_q15_normalizer #(
    parameter ACC_W = 64,
    parameter OUT_W = 24
) (
    input  signed [ACC_W-1:0]  accum,
    output signed [OUT_W-1:0]  data_out
);

    assign data_out = accum >>> 15;

endmodule