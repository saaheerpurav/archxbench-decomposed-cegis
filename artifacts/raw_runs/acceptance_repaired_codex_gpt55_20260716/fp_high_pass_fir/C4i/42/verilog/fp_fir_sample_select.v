`timescale 1ns/1ps

module fp_fir_sample_select #(
    parameter INDEX = 0
) (
    input  wire [31:0] new_sample,
    input  wire [31:0] hist_sample,
    output wire [31:0] sample_out
);

  assign sample_out = hist_sample;

endmodule