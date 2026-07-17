`timescale 1ns/1ps

module fir_output_scale #(
    parameter OUT_W = 24
) (
    input  signed [63:0] acc,
    output signed [OUT_W-1:0] data_out
);
    assign data_out = (acc >>> 15);
endmodule