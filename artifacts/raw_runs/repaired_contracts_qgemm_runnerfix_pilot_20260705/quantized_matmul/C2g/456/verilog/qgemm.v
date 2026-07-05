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

  integer i, j, kk;
  integer a_idx, b_idx, c_idx;
  integer acc;
  integer Aq, Bq;
  integer Azp, Bzp;
  real sA, sB;
  real aval, bval, outval;

  function real pow2_int;
    input integer e;
    integer n;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (n = 0; n < e; n = n + 1)
          r = r * 2.0;
      end else begin
        for (n = 0; n < -e; n = n + 1)
          r = r / 2.0;
      end
      pow2_int = r;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    integer exp;
    integer frac;
    real mant;
    begin
      sign = bits[31];
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        fp32_to_real = mant * pow2_int(-126);
        if (sign)
          fp32_to_real = -fp32_to_real;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant * pow2_int(exp - 127);
        if (sign)
          fp32_to_real = -fp32_to_real;
      end
    end
  endfunction

  function integer round_even_real;
    input real x;
    integer fl;
    real frac;
    begin
      if (x >= 0.0) begin
        fl = $rtoi(x);
        frac = x - fl;
        if (frac > 0.5)
          round_even_real = fl + 1;
        else if (frac < 0.5)
          round_even_real = fl;
        else
          round_even_real = (fl & 1) ? fl + 1 : fl;
      end else begin
        round_even_real = -round_even_real(-x);
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real x;
    reg sign;
    integer exp;
    integer biased;
    integer frac_floor;
    integer frac_bits;
    real ax;
    real mant;
    real scaled;
    real rem;
    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;

        exp = 0;
        mant = ax;

        while (mant >= 2.0) begin
          mant = mant / 2.0;
          exp = exp + 1;
        end

        while (mant < 1.0) begin
          mant = mant * 2.0;
          exp = exp - 1;
        end

        biased = exp + 127;

        if (biased <= 0) begin
          real_to_fp32 = {sign, 31'b0};
        end else if (biased >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          scaled = (mant - 1.0) * 8388608.0;
          frac_floor = $rtoi(scaled);
          rem = scaled - frac_floor;

          if (rem > 0.5)
            frac_bits = frac_floor + 1;
          else if (rem < 0.5)
            frac_bits = frac_floor;
          else
            frac_bits = (frac_floor & 1) ? frac_floor + 1 : frac_floor;

          if (frac_bits >= 8388608) begin
            frac_bits = 0;
            biased = biased + 1;
            if (biased >= 255)
              real_to_fp32 = {sign, 8'hff, 23'b0};
            else
              real_to_fp32 = {sign, biased[7:0], frac_bits[22:0]};
          end else begin
            real_to_fp32 = {sign, biased[7:0], frac_bits[22:0]};
          end
        end
      end
    end
  endfunction

  function integer signed_qbw;
    input [QBW-1:0] x;
    begin
      if (x[QBW-1])
        signed_qbw = x - (1 << QBW);
      else
        signed_qbw = x;
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {VLEN*VLEN*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= 1'b0;

      if (start) begin
        sA = scale_A / pow2_int(SCALE_Q);
        sB = scale_B / pow2_int(SCALE_Q);
        Azp = signed_qbw(zp_A);
        Bzp = signed_qbw(zp_B);

        for (i = 0; i < VLEN; i = i + 1) begin
          for (j = 0; j < VLEN; j = j + 1) begin
            acc = 0;

            for (kk = 0; kk < K; kk = kk + 1) begin
              a_idx = i*K + kk;
              b_idx = kk*VLEN + j;

              aval = fp32_to_real(A_fp[(VLEN*K-1-a_idx)*FP_W +: FP_W]);
              bval = fp32_to_real(B_fp[(K*VLEN-1-b_idx)*FP_W +: FP_W]);

              Aq = round_even_real(aval / sA) + Azp;
              Bq = round_even_real(bval / sB) + Bzp;

              Aq = signed_qbw(Aq[QBW-1:0]);
              Bq = signed_qbw(Bq[QBW-1:0]);

              acc = acc + ((Aq - Azp) * (Bq - Bzp));
            end

            c_idx = i*VLEN + j;
            outval = sA * sB * acc;
            C_fp[c_idx*FP_W +: FP_W] <= real_to_fp32(outval);
          end
        end

        done <= 1'b1;
      end
    end
  end

endmodule