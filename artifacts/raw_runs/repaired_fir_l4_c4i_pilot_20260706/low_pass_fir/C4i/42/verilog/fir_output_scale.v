`timescale 1ns/1ps

module fir_output_scale #(
    parameter ACC_W = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 20
) (
    input  signed [ACC_W-1:0] acc_in,
    output signed [OUT_W-1:0] data_out
);

    assign data_out = acc_in >>> (SHIFT - 1);

endmodule