`timescale 1ns/1ps

module qgemm #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter FP_W = 32,
  parameter SCALE_W = 16,
  parameter QBW = 8,
  parameter ACC_W = 32,
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

  localparam A_COUNT = VLEN*K;
  localparam B_COUNT = K*VLEN;
  localparam C_COUNT = VLEN*VLEN;

  wire signed [A_COUNT*ACC_W-1:0] A_centered;
  wire signed [B_COUNT*ACC_W-1:0] B_centered;
  wire signed [C_COUNT*ACC_W-1:0] C_acc_wire;
  wire [C_COUNT*FP_W-1:0] C_deq_wire;

  reg busy;
  reg [1:0] valid_pipe;

  qgemm_quantizer #(
    .COUNT(A_COUNT),
    .FP_W(FP_W),
    .SCALE_W(SCALE_W),
    .QBW(QBW),
    .OUT_W(ACC_W),
    .SCALE_Q(SCALE_Q)
  ) quant_A (
    .fp_in(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .centered_out(A_centered)
  );

  qgemm_quantizer #(
    .COUNT(B_COUNT),
    .FP_W(FP_W),
    .SCALE_W(SCALE_W),
    .QBW(QBW),
    .OUT_W(ACC_W),
    .SCALE_Q(SCALE_Q)
  ) quant_B (
    .fp_in(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .centered_out(B_centered)
  );

  qgemm_int_matmul #(
    .VLEN(VLEN),
    .K(K),
    .IN_W(ACC_W),
    .ACC_W(ACC_W)
  ) int_mm (
    .A_centered(A_centered),
    .B_centered(B_centered),
    .C_acc(C_acc_wire)
  );

  qgemm_dequantizer #(
    .COUNT(C_COUNT),
    .ACC_W(ACC_W),
    .FP_W(FP_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) deq (
    .acc_in(C_acc_wire),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .fp_out(C_deq_wire)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {C_COUNT*FP_W{1'b0}};
      done <= 1'b0;
      busy <= 1'b0;
      valid_pipe <= 2'b00;
    end else begin
      done <= 1'b0;

      if (start && !busy) begin
        busy <= 1'b1;
        valid_pipe <= 2'b01;
      end else begin
        valid_pipe <= {valid_pipe[0], 1'b0};
      end

      if (valid_pipe[1]) begin
        C_fp <= C_deq_wire;
        done <= 1'b1;
        busy <= 1'b0;
      end
    end
  end

endmodule