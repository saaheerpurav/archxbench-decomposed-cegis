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

  localparam A_Q_WIDTH = VLEN*K*ACC_W;
  localparam B_Q_WIDTH = K*VLEN*ACC_W;
  localparam C_ACC_WIDTH = VLEN*VLEN*ACC_W;
  localparam C_WIDTH = VLEN*VLEN*FP_W;

  wire [A_Q_WIDTH-1:0] A_q_centered;
  wire [B_Q_WIDTH-1:0] B_q_centered;
  wire [C_ACC_WIDTH-1:0] C_acc;
  wire [C_WIDTH-1:0] C_fp_comb;

  qgemm_quantize_tile #(
    .ROWS(VLEN),
    .COLS(K),
    .FP_W(FP_W),
    .QBW(QBW),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_A (
    .fp_in(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .q_centered(A_q_centered)
  );

  qgemm_quantize_tile #(
    .ROWS(K),
    .COLS(VLEN),
    .FP_W(FP_W),
    .QBW(QBW),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_B (
    .fp_in(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .q_centered(B_q_centered)
  );

  qgemm_int_gemm #(
    .VLEN(VLEN),
    .K(K),
    .ACC_W(ACC_W)
  ) gemm_core (
    .A_q_centered(A_q_centered),
    .B_q_centered(B_q_centered),
    .C_acc(C_acc)
  );

  qgemm_dequantize_tile #(
    .VLEN(VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {C_WIDTH{1'b0}};
      done <= 1'b0;
    end else begin
      done <= start;
      if (start)
        C_fp <= C_fp_comb;
    end
  end

endmodule