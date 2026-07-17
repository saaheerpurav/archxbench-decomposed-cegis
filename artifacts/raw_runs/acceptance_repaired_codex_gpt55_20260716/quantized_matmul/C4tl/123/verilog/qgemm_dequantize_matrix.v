`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ELEMS*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0]     scale_A,
  input  [SCALE_W-1:0]     scale_B,
  output reg [ELEMS*FP_W-1:0] C_fp
);

  integer i;
  integer acc_int;
  real scale_a_real;
  real scale_b_real;
  real deq_val;

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

  function integer round_to_even;
    input real x;
    integer base;
    real rem;
    begin
      base = $rtoi(x);
      rem = x - $itor(base);

      if (rem > 0.5)
        round_to_even = base + 1;
      else if (rem < 0.5)
        round_to_even = base;
      else if (base[0])
        round_to_even = base + 1;
      else
        round_to_even = base;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real value;
    reg sign;
    integer exp_unbiased;
    integer exp_biased;
    integer frac;
    integer sig;
    real abs_val;
    real norm;
    real frac_real;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (value < 0.0);
        abs_val = sign ? -value : value;

        exp_unbiased = 0;
        norm = abs_val;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'd0};
        end else if (exp_biased <= 0) begin
          frac_real = abs_val / pow2(-149);
          sig = round_to_even(frac_real);

          if (sig <= 0)
            real_to_fp32 = {sign, 31'd0};
          else if (sig >= 8388608)
            real_to_fp32 = {sign, 8'd1, 23'd0};
          else
            real_to_fp32 = {sign, 8'd0, sig[22:0]};
        end else begin
          frac_real = (norm - 1.0) * 8388608.0;
          frac = round_to_even(frac_real);

          if (frac >= 8388608) begin
            frac = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign, 8'hff, 23'd0};
          else
            real_to_fp32 = {sign, exp_biased[7:0], frac[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {ELEMS*FP_W{1'b0}};

    scale_a_real = $itor(scale_A) / pow2(SCALE_Q);
    scale_b_real = $itor(scale_B) / pow2(SCALE_Q);

    for (i = 0; i < ELEMS; i = i + 1) begin
      acc_int = $signed(C_acc[i*ACC_W +: ACC_W]);
      deq_val = $itor(acc_int) * scale_a_real * scale_b_real;
      C_fp[i*FP_W +: FP_W] = real_to_fp32(deq_val);
    end
  end

endmodule