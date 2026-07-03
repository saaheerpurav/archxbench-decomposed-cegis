`timescale 1ns/1ps

module conv1d_scale #(
    parameter ACC_W = 20,
    parameter OUT_W = 12,
    parameter SHIFT = 4
) (
    input  [ACC_W-1:0] sum_in,
    output [OUT_W-1:0] data_out
);

    wire signed [ACC_W-1:0] sum_signed;
    wire signed [ACC_W-1:0] shifted_sum;

    assign sum_signed  = $signed(sum_in);
    assign shifted_sum = sum_signed >>> SHIFT;

    assign data_out = shifted_sum[OUT_W-1:0];

endmodule