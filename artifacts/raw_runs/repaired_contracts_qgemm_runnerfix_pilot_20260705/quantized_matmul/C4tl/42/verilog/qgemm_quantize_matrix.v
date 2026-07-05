`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ELEMS*FP_W-1:0] fp_in,
  input [SCALE_W-1:0] scale,
  input [QBW-1:0] zp,
  output [ELEMS*QBW-1:0] q_out
);

  genvar g;
  generate
    for (g = 0; g < ELEMS; g = g + 1) begin : gen_quant
      wire [FP_W-1:0] fp_word;
      assign fp_word = fp_in[(ELEMS-1-g)*FP_W +: FP_W];

      qgemm_quantize_elem #(
        .FP_W(FP_W),
        .QBW(QBW),
        .SCALE_W(SCALE_W),
        .SCALE_Q(SCALE_Q)
      ) elem (
        .fp_in(fp_word),
        .scale(scale),
        .zp(zp),
        .q_out(q_out[g*QBW +: QBW])
      );
    end
  endgenerate

endmodule