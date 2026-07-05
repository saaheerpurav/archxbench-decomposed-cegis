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

  wire [A_ELEMS*QBW-1:0] A_q;
  wire [B_ELEMS*QBW-1:0] B_q;
  wire [C_ELEMS*ACC_W-1:0] C_acc;
  wire [C_ELEMS*FP_W-1:0] C_fp_comb;

  genvar ai, bi;
  generate
    for (ai = 0; ai < A_ELEMS; ai = ai + 1) begin : GEN_A_QUANT
      qgemm_quantize_elem #(
        .FP_W(FP_W),
        .QBW(QBW),
        .SCALE_W(SCALE_W),
        .SCALE_Q(SCALE_Q)
      ) u_a_quant (
        .fp_in(A_fp[(A_ELEMS-1-ai)*FP_W +: FP_W]),
        .scale(scale_A),
        .zp(zp_A),
        .q_out(A_q[ai*QBW +: QBW])
      );
    end

    for (bi = 0; bi < B_ELEMS; bi = bi + 1) begin : GEN_B_QUANT
      qgemm_quantize_elem #(
        .FP_W(FP_W),
        .QBW(QBW),
        .SCALE_W(SCALE_W),
        .SCALE_Q(SCALE_Q)
      ) u_b_quant (
        .fp_in(B_fp[(B_ELEMS-1-bi)*FP_W +: FP_W]),
        .scale(scale_B),
        .zp(zp_B),
        .q_out(B_q[bi*QBW +: QBW])
      );
    end
  endgenerate

  qgemm_int_matmul #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) u_int_matmul (
    .A_q(A_q),
    .B_q(B_q),
    .zp_A(zp_A),
    .zp_B(zp_B),
    .C_acc(C_acc)
  );

  qgemm_dequant_matrix #(
    .VLEN(VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) u_dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {C_ELEMS*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      if (start) begin
        C_fp <= C_fp_comb;
        done <= 1'b1;
      end else begin
        done <= 1'b0;
      end
    end
  end

endmodule