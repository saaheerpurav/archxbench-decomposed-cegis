`timescale 1ns/1ps

module qgemm_fp32_quant #(
  parameter VLEN    = 8,
  parameter K       = 64,
  parameter FP_W    = 32,
  parameter QBW     = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [VLEN*K*FP_W-1:0] A_fp,
  input  wire [K*VLEN*FP_W-1:0] B_fp,
  input  wire [SCALE_W-1:0]     scale_A,
  input  wire [SCALE_W-1:0]     scale_B,
  input  wire [QBW-1:0]         zp_A,
  input  wire [QBW-1:0]         zp_B,
  output reg  [VLEN*K*QBW-1:0]  A_q,
  output reg  [K*VLEN*QBW-1:0]  B_q
);

  localparam A_ELEMS = VLEN * K;
  localparam B_ELEMS = K * VLEN;

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    real mant;
    integer e;
    begin
      sign = bits[31];
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 8'h00) begin
        if (frac == 23'd0) begin
          fp32_to_real = 0.0;
        end else begin
          mant = frac / 8388608.0;
          fp32_to_real = mant * (2.0 ** (-126));
        end
      end else if (exp == 8'hff) begin
        fp32_to_real = 0.0;
      end else begin
        e = exp - 127;
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant * (2.0 ** e);
      end

      if (sign)
        fp32_to_real = -fp32_to_real;
    end
  endfunction

  function integer round_real_to_int;
    input real value;
    begin
      if (value >= 0.0)
        round_real_to_int = value + 0.5;
      else
        round_real_to_int = value - 0.5;
    end
  endfunction

  function [QBW-1:0] quantize_fp32;
    input [31:0] fp_bits;
    input [SCALE_W-1:0] scale_q15;
    input [QBW-1:0] zp;
    real fp_val;
    real scale_val;
    real scaled_val;
    integer q_tmp;
    integer q_min;
    integer q_max;
    begin
      q_min = 0;
      q_max = (1 << QBW) - 1;

      if (scale_q15 == {SCALE_W{1'b0}}) begin
        q_tmp = zp;
      end else begin
        fp_val = fp32_to_real(fp_bits);
        scale_val = scale_q15;
        scale_val = scale_val / (2.0 ** SCALE_Q);
        scaled_val = fp_val / scale_val;
        q_tmp = round_real_to_int(scaled_val) + zp;
      end

      if (q_tmp < q_min)
        quantize_fp32 = {QBW{1'b0}};
      else if (q_tmp > q_max)
        quantize_fp32 = q_max[QBW-1:0];
      else
        quantize_fp32 = q_tmp[QBW-1:0];
    end
  endfunction

  integer i;
  reg [FP_W-1:0] fp_lane;

  always @* begin
    A_q = {VLEN*K*QBW{1'b0}};
    B_q = {K*VLEN*QBW{1'b0}};

    for (i = 0; i < A_ELEMS; i = i + 1) begin
      fp_lane = A_fp[((A_ELEMS-1-i)*FP_W) +: FP_W];
      A_q[((A_ELEMS-1-i)*QBW) +: QBW] = quantize_fp32(fp_lane, scale_A, zp_A);
    end

    for (i = 0; i < B_ELEMS; i = i + 1) begin
      fp_lane = B_fp[((B_ELEMS-1-i)*FP_W) +: FP_W];
      B_q[((B_ELEMS-1-i)*QBW) +: QBW] = quantize_fp32(fp_lane, scale_B, zp_B);
    end
  end

endmodule