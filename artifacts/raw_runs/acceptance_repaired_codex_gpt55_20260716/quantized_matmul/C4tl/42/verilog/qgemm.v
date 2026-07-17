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

  wire [VLEN*K*QBW-1:0] A_q_comb;
  wire [K*VLEN*QBW-1:0] B_q_comb;
  wire [VLEN*VLEN*ACC_W-1:0] C_acc_comb;
  wire [VLEN*VLEN*FP_W-1:0] C_fp_comb;

  reg [VLEN*K*QBW-1:0] A_q_reg;
  reg [K*VLEN*QBW-1:0] B_q_reg;
  reg [VLEN*VLEN*ACC_W-1:0] C_acc_reg;
  reg [SCALE_W-1:0] scale_A_d0, scale_B_d0;
  reg [SCALE_W-1:0] scale_A_d1, scale_B_d1;
  reg [QBW-1:0] zp_A_d0, zp_B_d0;
  reg [1:0] valid_pipe;

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
    .q_matrix(A_q_comb)
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
    .q_matrix(B_q_comb)
  );

  qgemm_int_matrix_multiply #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) int_gemm (
    .A_q(A_q_reg),
    .B_q(B_q_reg),
    .zp_A(zp_A_d0),
    .zp_B(zp_B_d0),
    .C_acc(C_acc_comb)
  );

  qgemm_dequantize_matrix #(
    .VLEN(VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant (
    .C_acc(C_acc_reg),
    .scale_A(scale_A_d1),
    .scale_B(scale_B_d1),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      A_q_reg <= 0;
      B_q_reg <= 0;
      C_acc_reg <= 0;
      C_fp <= 0;
      done <= 1'b0;
      valid_pipe <= 2'b00;
      scale_A_d0 <= 0;
      scale_B_d0 <= 0;
      scale_A_d1 <= 0;
      scale_B_d1 <= 0;
      zp_A_d0 <= 0;
      zp_B_d0 <= 0;
    end else begin
      done <= 1'b0;

      if (start) begin
        A_q_reg <= A_q_comb;
        B_q_reg <= B_q_comb;
        scale_A_d0 <= scale_A;
        scale_B_d0 <= scale_B;
        zp_A_d0 <= zp_A;
        zp_B_d0 <= zp_B;
      end

      if (valid_pipe[0]) begin
        C_acc_reg <= C_acc_comb;
        scale_A_d1 <= scale_A_d0;
        scale_B_d1 <= scale_B_d0;
      end

      if (valid_pipe[1]) begin
        C_fp <= C_fp_comb;
        done <= 1'b1;
      end

      valid_pipe <= {valid_pipe[0], start};
    end
  end

endmodule