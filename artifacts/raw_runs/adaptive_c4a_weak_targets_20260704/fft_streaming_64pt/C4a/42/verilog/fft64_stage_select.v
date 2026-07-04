`timescale 1ns/1ps

module fft64_stage_select #(
    parameter DATA_W = 20
) (
    input  wire                         select_upper,
    input  wire signed [DATA_W-1:0]     sum_real,
    input  wire signed [DATA_W-1:0]     sum_imag,
    input  wire signed [DATA_W-1:0]     diff_real,
    input  wire signed [DATA_W-1:0]     diff_imag,
    output wire signed [DATA_W-1:0]     out_real,
    output wire signed [DATA_W-1:0]     out_imag
);

    assign out_real = select_upper ? sum_real : diff_real;
    assign out_imag = select_upper ? sum_imag : diff_imag;

endmodule