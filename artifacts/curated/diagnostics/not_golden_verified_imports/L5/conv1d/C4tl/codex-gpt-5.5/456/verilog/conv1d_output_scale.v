`timescale 1ns/1ps

module conv1d_output_scale #(
    parameter ACC_W = 16,
    parameter OUT_W = 12,
    parameter SHIFT = 4
) (
    input  [ACC_W-1:0] sum_in,
    output [OUT_W-1:0] data_out
);

    wire signed [ACC_W-1:0] sum_signed;
    wire signed [ACC_W-1:0] scaled_signed;

    assign sum_signed    = sum_in;
    assign scaled_signed = sum_signed >>> SHIFT;
    assign data_out      = scaled_signed[OUT_W-1:0];

endmodule