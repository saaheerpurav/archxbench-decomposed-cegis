`timescale 1ns/1ps

module conv3d_output_clip #(
    parameter IN_W = 24,
    parameter OUT_W = 12
) (
    input [IN_W-1:0] sum_in,
    output [OUT_W-1:0] data_out
);
    assign data_out = sum_in[OUT_W-1:0];
endmodule