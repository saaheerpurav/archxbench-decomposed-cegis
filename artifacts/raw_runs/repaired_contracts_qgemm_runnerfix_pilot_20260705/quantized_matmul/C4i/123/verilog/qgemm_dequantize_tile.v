`timescale 1ns/1ps

module qgemm_dequantize_tile #(
  parameter ELEMS = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ELEMS*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0] scale_A,
  input  [SCALE_W-1:0] scale_B,
  output reg [ELEMS*FP_W-1:0] C_fp
);

  localparam DEN_SHIFT = 2*SCALE_Q;

  integer i;
  reg signed [ACC_W-1:0] acc_s;
  reg sign;
  reg [ACC_W-1:0] acc_mag;
  reg [127:0] numer;

  function integer msb_pos;
    input [127:0] x;
    integer b;
    begin
      msb_pos = -1;
      for (b = 0; b < 128; b = b + 1) begin
        if (x[b])
          msb_pos = b;
      end
    end
  endfunction

  function [31:0] rational_q_to_fp32;
    input sign_in;
    input [127:0] num;
    integer p;
    integer exp_unbiased;
    integer exp_field;
    integer shift;
    reg [127:0] shifted;
    reg [127:0] rem;
    reg [127:0] half;
    reg [24:0] sig;
    reg round_up;
    reg [22:0] mant;
    begin
      if (num == 0) begin
        rational_q_to_fp32 = 32'h00000000;
      end else begin
        p = msb_pos(num);
        exp_unbiased = p - DEN_SHIFT;
        exp_field = exp_unbiased + 127;

        if (exp_field <= 0) begin
          rational_q_to_fp32 = {sign_in, 31'h00000000};
        end else if (exp_field >= 255) begin
          rational_q_to_fp32 = {sign_in, 8'hff, 23'h000000};
        end else begin
          shift = p - 23;

          if (shift > 0) begin
            shifted = num >> shift;
            rem = num - (shifted << shift);
            half = 128'd1 << (shift - 1);
            round_up = (rem > half) || ((rem == half) && shifted[0]);
            sig = shifted[24:0] + round_up;
          end else begin
            sig = num[24:0] << (-shift);
          end

          if (sig[24]) begin
            sig = sig >> 1;
            exp_field = exp_field + 1;
          end

          if (exp_field >= 255) begin
            rational_q_to_fp32 = {sign_in, 8'hff, 23'h000000};
          end else begin
            mant = sig[22:0];
            rational_q_to_fp32 = {sign_in, exp_field[7:0], mant};
          end
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {ELEMS*FP_W{1'b0}};

    for (i = 0; i < ELEMS; i = i + 1) begin
      acc_s = $signed(C_acc[i*ACC_W +: ACC_W]);
      sign = acc_s[ACC_W-1];

      if (sign)
        acc_mag = -acc_s;
      else
        acc_mag = acc_s;

      numer = acc_mag;
      numer = numer * scale_A;
      numer = numer * scale_B;

      C_fp[i*FP_W +: FP_W] = rational_q_to_fp32(sign, numer);
    end
  end

endmodule