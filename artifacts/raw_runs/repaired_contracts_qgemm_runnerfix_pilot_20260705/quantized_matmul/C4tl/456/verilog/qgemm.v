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

  wire [VLEN*K*QBW-1:0] A_q;
  wire [K*VLEN*QBW-1:0] B_q;
  wire [VLEN*VLEN*ACC_W-1:0] C_acc;
  wire [VLEN*VLEN*FP_W-1:0] C_comb;

  qgemm_quantize_matrix #(
    .ELEM_COUNT(VLEN*K),
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
    .ELEM_COUNT(K*VLEN),
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
  ) matmul (
    .A_q(A_q),
    .B_q(B_q),
    .zp_A(zp_A),
    .zp_B(zp_B),
    .C_acc(C_acc)
  );

  qgemm_dequantize_matrix #(
    .ELEM_COUNT(VLEN*VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {VLEN*VLEN*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        C_fp <= C_comb;
        done <= 1'b1;
      end
    end
  end

endmodule