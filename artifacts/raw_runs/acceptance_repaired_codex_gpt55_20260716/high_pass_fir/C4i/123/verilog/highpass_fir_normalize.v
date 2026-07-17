`timescale 1ns/1ps

module highpass_fir_normalize #(
    parameter ACC_W = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 15
) (
    input  signed [ACC_W-1:0] accum,
    output signed [OUT_W-1:0] data_out
);

    assign data_out = accum >>> SHIFT;

endmodule