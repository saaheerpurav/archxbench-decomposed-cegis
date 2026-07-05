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

  wire signed [A_ELEMS*QBW-1:0] A_centered;
  wire signed [B_ELEMS*QBW-1:0] B_centered;
  wire signed [C_ELEMS*ACC_W-1:0] C_acc;
  wire [C_ELEMS*FP_W-1:0] C_next;

  qgemm_quantize_matrix #(
    .ELEMS(A_ELEMS),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_A (
    .fp_in(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .centered_q(A_centered)
  );

  qgemm_quantize_matrix #(
    .ELEMS(B_ELEMS),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) quant_B (
    .fp_in(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .centered_q(B_centered)
  );

  qgemm_int_matmul #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) matmul (
    .A_centered(A_centered),
    .B_centered(B_centered),
    .C_acc(C_acc)
  );

  qgemm_dequantize_matrix #(
    .ELEMS(C_ELEMS),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_next)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {C_ELEMS*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= start;
      if (start)
        C_fp <= C_next;
    end
  end

endmodule