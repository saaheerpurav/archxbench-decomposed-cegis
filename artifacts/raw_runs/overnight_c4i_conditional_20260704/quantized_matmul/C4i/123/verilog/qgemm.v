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
  output [VLEN*VLEN*FP_W-1:0] C_fp,
  output reg done
);

  localparam A_COUNT = VLEN*K;
  localparam B_COUNT = K*VLEN;
  localparam C_COUNT = VLEN*VLEN;

  wire [A_COUNT*QBW-1:0] A_q;
  wire [B_COUNT*QBW-1:0] B_q;
  wire [C_COUNT*ACC_W-1:0] C_acc;
  wire [C_COUNT*FP_W-1:0] C_fp_comb;

  reg [C_COUNT*FP_W-1:0] C_fp_reg;

  qgemm_quantize_matrix #(
    .COUNT(A_COUNT),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_A (
    .fp_in(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .q_out(A_q)
  );

  qgemm_quantize_matrix #(
    .COUNT(B_COUNT),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_B (
    .fp_in(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .q_out(B_q)
  );

  qgemm_int_matmul #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) gemm_i (
    .A_q(A_q),
    .B_q(B_q),
    .zp_A(zp_A),
    .zp_B(zp_B),
    .C_acc(C_acc)
  );

  qgemm_dequantize_matrix #(
    .COUNT(C_COUNT),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant_C (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  assign C_fp = C_fp_reg;

  always @(posedge clk) begin
    if (rst) begin
      C_fp_reg <= {C_COUNT*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        C_fp_reg <= C_fp_comb;
        done <= 1'b1;
      end
    end
  end

endmodule