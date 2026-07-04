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
  input  wire clk,
  input  wire rst,
  input  wire start,
  input  wire [VLEN*K*FP_W-1:0] A_fp,
  input  wire [K*VLEN*FP_W-1:0] B_fp,
  input  wire [SCALE_W-1:0] scale_A,
  input  wire [SCALE_W-1:0] scale_B,
  input  wire [QBW-1:0] zp_A,
  input  wire [QBW-1:0] zp_B,
  output reg  [VLEN*VLEN*FP_W-1:0] C_fp,
  output reg  done
);

  localparam A_Q_WIDTH = VLEN*K*QBW;
  localparam B_Q_WIDTH = K*VLEN*QBW;
  localparam C_ACC_WIDTH = VLEN*VLEN*ACC_W;

  wire [A_Q_WIDTH-1:0] A_q;
  wire [B_Q_WIDTH-1:0] B_q;
  wire [C_ACC_WIDTH-1:0] C_acc;
  wire [VLEN*VLEN*FP_W-1:0] C_fp_comb;

  qgemm_quantize_a #(
    .VLEN(VLEN), .K(K), .FP_W(FP_W), .QBW(QBW),
    .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
  ) quant_a (
    .A_fp(A_fp),
    .scale_A(scale_A),
    .zp_A(zp_A),
    .A_q(A_q)
  );

  qgemm_quantize_b #(
    .VLEN(VLEN), .K(K), .FP_W(FP_W), .QBW(QBW),
    .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
  ) quant_b (
    .B_fp(B_fp),
    .scale_B(scale_B),
    .zp_B(zp_B),
    .B_q(B_q)
  );

  qgemm_int_matmul #(
    .VLEN(VLEN), .K(K), .QBW(QBW), .ACC_W(ACC_W)
  ) matmul (
    .A_q(A_q),
    .B_q(B_q),
    .zp_A(zp_A),
    .zp_B(zp_B),
    .C_acc(C_acc)
  );

  qgemm_dequantize #(
    .VLEN(VLEN), .FP_W(FP_W), .ACC_W(ACC_W),
    .SCALE_W(SCALE_W), .SCALE_Q(SCALE_Q)
  ) dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {VLEN*VLEN*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= start;
      if (start)
        C_fp <= C_fp_comb;
    end
  end

endmodule