`timescale 1ns/1ps

module qgemm #(
  parameter VLEN    = 8,
  parameter K       = 64,
  parameter FP_W    = 32,
  parameter QBW     = 8,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire                         clk,
  input  wire                         rst,
  input  wire                         start,
  input  wire [VLEN*K*FP_W-1:0]       A_fp,
  input  wire [K*VLEN*FP_W-1:0]       B_fp,
  input  wire [SCALE_W-1:0]           scale_A,
  input  wire [SCALE_W-1:0]           scale_B,
  input  wire [QBW-1:0]               zp_A,
  input  wire [QBW-1:0]               zp_B,
  output reg  [VLEN*VLEN*FP_W-1:0]    C_fp,
  output reg                          done
);

  integer i, j, kk;
  integer acc;
  integer aq, bq;
  integer zpa_s, zpb_s;
  real    a_scale;
  real    b_scale;
  real    out_real;

  function real pow2;
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
      pow2 = r;
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
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 0) begin
        if (frac == 0)
          fp32_to_real = 0.0;
        else begin
          mant = frac / 8388608.0;
          fp32_to_real = mant * pow2(-126);
          if (sign) fp32_to_real = -fp32_to_real;
        end
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant * pow2(exp - 127);
        if (sign) fp32_to_real = -fp32_to_real;
      end
    end
  endfunction

  function integer round_nearest;
    input real x;
    integer t;
    begin
      if (x >= 0.0)
        round_nearest = $rtoi(x + 0.5);
      else
        round_nearest = $rtoi(x - 0.5);
    end
  endfunction

  function integer wrap_signed_q;
    input integer x;
    integer mask;
    integer modv;
    integer half;
    begin
      mask = (1 << QBW) - 1;
      modv = x & mask;
      half = 1 << (QBW - 1);
      if (modv >= half)
        wrap_signed_q = modv - (1 << QBW);
      else
        wrap_signed_q = modv;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real val;
    reg sign;
    real x;
    real norm;
    integer exp_unbiased;
    integer exp_biased;
    integer mant;
    begin
      if (val == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (val < 0.0);
        x = sign ? -val : val;

        exp_unbiased = 0;
        norm = x;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          real_to_fp32 = {sign, 31'b0};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          mant = round_nearest((norm - 1.0) * 8388608.0);

          if (mant >= 8388608) begin
            mant = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign, 8'hff, 23'b0};
          else
            real_to_fp32 = {sign, exp_biased[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  function [31:0] get_a_word;
    input integer idx;
    begin
      get_a_word = A_fp[(VLEN*K-1-idx)*FP_W +: FP_W];
    end
  endfunction

  function [31:0] get_b_word;
    input integer idx;
    begin
      get_b_word = B_fp[(K*VLEN-1-idx)*FP_W +: FP_W];
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {VLEN*VLEN*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      done <= 1'b0;

      if (start) begin
        a_scale = scale_A / pow2(SCALE_Q);
        b_scale = scale_B / pow2(SCALE_Q);
        zpa_s = wrap_signed_q(zp_A);
        zpb_s = wrap_signed_q(zp_B);

        for (i = 0; i < VLEN; i = i + 1) begin
          for (j = 0; j < VLEN; j = j + 1) begin
            acc = 0;

            for (kk = 0; kk < K; kk = kk + 1) begin
              aq = round_nearest(fp32_to_real(get_a_word(i*K + kk)) / a_scale) + zpa_s;
              bq = round_nearest(fp32_to_real(get_b_word(kk*VLEN + j)) / b_scale) + zpb_s;

              aq = wrap_signed_q(aq);
              bq = wrap_signed_q(bq);

              acc = acc + ((aq - zpa_s) * (bq - zpb_s));
            end

            out_real = a_scale * b_scale * acc;
            C_fp[(i*VLEN + j)*FP_W +: FP_W] <= real_to_fp32(out_real);
          end
        end

        done <= 1'b1;
      end
    end
  end

endmodule