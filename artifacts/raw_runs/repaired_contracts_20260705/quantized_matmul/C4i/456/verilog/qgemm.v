`timescale 1ns/1ps

module qgemm #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input clk,
  input rst,
  input start,
  input [VLEN*K*FP_W-1:0] A_fp,
  input [K*VLEN*FP_W-1:0] B_fp,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  input [QBW-1:0] zp_A,
  input [QBW-1:0] zp_B,
  output reg [VLEN*VLEN*FP_W-1:0] C_fp,
  output reg done
);

  localparam A_ELEMS = VLEN*K;
  localparam B_ELEMS = K*VLEN;
  localparam C_ELEMS = VLEN*VLEN;

  wire signed [QBW:0] A_centered [0:A_ELEMS-1];
  wire signed [QBW:0] B_centered [0:B_ELEMS-1];
  wire signed [ACC_W-1:0] C_acc [0:C_ELEMS-1];
  wire [FP_W-1:0] C_deq [0:C_ELEMS-1];

  genvar ai, bi, ci, cj;
  generate
    for (ai = 0; ai < A_ELEMS; ai = ai + 1) begin : GEN_A_QUANT
      fp32_q15_quantizer #(
        .FP_W(FP_W), .QBW(QBW), .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
      ) a_quant (
        .fp_in(A_fp[(A_ELEMS-1-ai)*FP_W +: FP_W]),
        .scale_q15(scale_A),
        .zero_point(zp_A),
        .centered_q(A_centered[ai])
      );
    end

    for (bi = 0; bi < B_ELEMS; bi = bi + 1) begin : GEN_B_QUANT
      fp32_q15_quantizer #(
        .FP_W(FP_W), .QBW(QBW), .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
      ) b_quant (
        .fp_in(B_fp[(B_ELEMS-1-bi)*FP_W +: FP_W]),
        .scale_q15(scale_B),
        .zero_point(zp_B),
        .centered_q(B_centered[bi])
      );
    end

    for (ci = 0; ci < VLEN; ci = ci + 1) begin : GEN_ROWS
      for (cj = 0; cj < VLEN; cj = cj + 1) begin : GEN_COLS
        int_dot_product #(
          .K(K), .QBW(QBW), .ACC_W(ACC_W)
        ) dot (
          .a_vec(flat_a_row(ci)),
          .b_vec(flat_b_col(cj)),
          .acc(C_acc[ci*VLEN+cj])
        );

        q15_dequantizer #(
          .FP_W(FP_W), .ACC_W(ACC_W), .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
        ) deq (
          .acc(C_acc[ci*VLEN+cj]),
          .scale_A(scale_A),
          .scale_B(scale_B),
          .fp_out(C_deq[ci*VLEN+cj])
        );
      end
    end
  endgenerate

  function [K*(QBW+1)-1:0] flat_a_row;
    input integer row;
    integer kk;
    begin
      flat_a_row = 0;
      for (kk = 0; kk < K; kk = kk + 1)
        flat_a_row[kk*(QBW+1) +: (QBW+1)] = A_centered[row*K + kk];
    end
  endfunction

  function [K*(QBW+1)-1:0] flat_b_col;
    input integer col;
    integer kk;
    begin
      flat_b_col = 0;
      for (kk = 0; kk < K; kk = kk + 1)
        flat_b_col[kk*(QBW+1) +: (QBW+1)] = B_centered[kk*VLEN + col];
    end
  endfunction

  integer out_i;
  always @(posedge clk) begin
    if (rst) begin
      C_fp <= 0;
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        for (out_i = 0; out_i < C_ELEMS; out_i = out_i + 1)
          C_fp[out_i*FP_W +: FP_W] <= C_deq[out_i];
        done <= 1'b1;
      end
    end
  end

endmodule