`timescale 1ns/1ps

module hp_sample_packer #(
    parameter TAP_CNT = 101
) (
    input wire [TAP_CNT*32-1:0] sample_words,
    output wire [TAP_CNT*32-1:0] samples_flat
);
  assign samples_flat = sample_words;
endmodule