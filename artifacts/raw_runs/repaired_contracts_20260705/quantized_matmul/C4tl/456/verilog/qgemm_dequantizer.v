`timescale 1ns/1ps

module qgemm_dequantizer #(
  parameter COUNT = 64,
  parameter ACC_W = 32,
  parameter FP_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input signed [COUNT*ACC_W-1:0] acc_in,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [COUNT*FP_W-1:0] fp_out
);

  integer idx;
  reg signed [ACC_W-1:0] acc_val;

  function [31:0] scaled_acc_to_fp32;
    input signed [ACC_W-1:0] acc;
    input [SCALE_W-1:0] sA;
    input [SCALE_W-1:0] sB;
    reg sign;
    reg [127:0] absnum;
    reg [127:0] den;
    reg [127:0] norm;
    reg [127:0] rem;
    reg [24:0] mant_ext;
    reg [22:0] frac;
    integer msb;
    integer exp_unbiased;
    integer exp_biased;
    integer n;
    begin
      if (acc == 0 || sA == 0 || sB == 0) begin
        scaled_acc_to_fp32 = 32'h00000000;
      end else begin
        sign = acc[ACC_W-1];
        if (sign)
          absnum = -acc;
        else
          absnum = acc;

        absnum = absnum * sA * sB;
        den = 128'd1 << (2*SCALE_Q);

        msb = 0;
        for (n = 0; n < 128; n = n + 1)
          if (absnum[n])
            msb = n;

        exp_unbiased = msb - (2*SCALE_Q);
        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          scaled_acc_to_fp32 = {sign, 31'b0};
        end else if (exp_biased >= 255) begin
          scaled_acc_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          if (msb >= 24)
            norm = absnum >> (msb - 24);
          else
            norm = absnum << (24 - msb);

          if (msb >= 24)
            rem = absnum & ((128'd1 << (msb - 24)) - 1);
          else
            rem = 0;

          mant_ext = norm[24:0];

          if (msb >= 24 && (rem > (128'd1 << (msb - 25)) ||
              (rem == (128'd1 << (msb - 25)) && mant_ext[0]))) begin
            mant_ext = mant_ext + 1'b1;
          end

          if (mant_ext[24]) begin
            frac = mant_ext[23:1];
            exp_biased = exp_biased + 1;
          end else begin
            frac = mant_ext[22:0];
          end

          if (exp_biased >= 255)
            scaled_acc_to_fp32 = {sign, 8'hff, 23'b0};
          else
            scaled_acc_to_fp32 = {sign, exp_biased[7:0], frac};
        end
      end
    end
  endfunction

  always @* begin
    for (idx = 0; idx < COUNT; idx = idx + 1) begin
      acc_val = acc_in[idx*ACC_W +: ACC_W];
      fp_out[idx*FP_W +: FP_W] = scaled_acc_to_fp32(acc_val, scale_A, scale_B);
    end
  end

endmodule