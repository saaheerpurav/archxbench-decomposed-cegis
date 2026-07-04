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

  localparam A_INT_W = VLEN*K*QBW;
  localparam B_INT_W = K*VLEN*QBW;
  localparam C_ACC_W = VLEN*VLEN*ACC_W;
  localparam C_FP_W  = VLEN*VLEN*FP_W;

  wire [A_INT_W-1:0] A_centered;
  wire [B_INT_W-1:0] B_centered;
  wire [C_ACC_W-1:0] C_acc;
  wire [C_FP_W-1:0]  C_fp_comb;

  qgemm_quantize_matrix #(
    .ROWS(VLEN),
    .COLS(K),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_A (
    .fp_matrix(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .centered_matrix(A_centered)
  );

  qgemm_quantize_matrix #(
    .ROWS(K),
    .COLS(VLEN),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_B (
    .fp_matrix(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .centered_matrix(B_centered)
  );

  qgemm_int_matmul #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) matmul_i (
    .A_centered(A_centered),
    .B_centered(B_centered),
    .C_acc(C_acc)
  );

  qgemm_dequantize_matrix #(
    .VLEN(VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant_i (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {C_FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        C_fp <= C_fp_comb;
        done <= 1'b1;
      end
    end
  end

endmodule