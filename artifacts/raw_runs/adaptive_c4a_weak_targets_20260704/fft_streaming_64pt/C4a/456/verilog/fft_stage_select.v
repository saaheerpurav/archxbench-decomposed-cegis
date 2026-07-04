`timescale 1ns/1ps

module fft_stage_select #(
    parameter DATA_W = 20,
    parameter STAGE  = 0
) (
    input  [5:0] sample_index,
    input  signed [DATA_W-1:0] sum_real,
    input  signed [DATA_W-1:0] sum_imag,
    input  signed [DATA_W-1:0] diff_real,
    input  signed [DATA_W-1:0] diff_imag,
    output signed [DATA_W-1:0] out_real,
    output signed [DATA_W-1:0] out_imag
);

    wire select_diff;

    assign select_diff = sample_index[STAGE];

    assign out_real = select_diff ? diff_real : sum_real;
    assign out_imag = select_diff ? diff_imag : sum_imag;

endmodule