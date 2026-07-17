`timescale 1ns/1ps

module fir_shift_next #(
    parameter TAP_CNT = 101
) (
    input  wire valid_in,
    input  wire [31:0] data_in,
    input  wire [TAP_CNT*32-1:0] hist_in,
    output wire [TAP_CNT*32-1:0] hist_out
);

  genvar i;

  generate
    for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_SHIFT_NEXT
      if (i == 0) begin : GEN_HEAD
        assign hist_out[i*32 +: 32] =
            valid_in ? data_in : hist_in[i*32 +: 32];
      end else begin : GEN_TAIL
        assign hist_out[i*32 +: 32] =
            valid_in ? hist_in[(i-1)*32 +: 32] : hist_in[i*32 +: 32];
      end
    end
  endgenerate

endmodule