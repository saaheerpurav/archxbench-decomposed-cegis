`timescale 1ns/1ps

module fp_fir_sample_bank #(
    parameter TAP_CNT = 101
) (
    input  wire [31:0] samples_flat [0:TAP_CNT-1],
    output wire [32*TAP_CNT-1:0] sample_vector
);

  genvar i;

  generate
    for (i = 0; i < TAP_CNT; i = i + 1) begin : g_pack_samples
      assign sample_vector[(32*i) +: 32] = samples_flat[i];
    end
  endgenerate

endmodule