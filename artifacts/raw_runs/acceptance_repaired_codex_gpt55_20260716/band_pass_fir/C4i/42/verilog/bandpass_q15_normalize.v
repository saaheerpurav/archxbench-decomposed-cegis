`timescale 1ns/1ps

module bandpass_q15_normalize #(
    parameter OUT_W = 24
) (
    input  signed [63:0]      sum_in,
    output signed [OUT_W-1:0] data_out
);

    assign data_out = sum_in >>> 15;

endmodule