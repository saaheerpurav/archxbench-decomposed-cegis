`timescale 1ns/1ps

module qgemm_dequantizer #(
  parameter NUM = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [NUM*ACC_W-1:0] C_acc,
  input  wire [SCALE_W-1:0] scale_A,
  input  wire [SCALE_W-1:0] scale_B,
  output reg  [NUM*FP_W-1:0] C_fp
);

  integer i;
  reg signed [ACC_W-1:0] acc_s;
  real scale_a_real;
  real scale_b_real;
  real out_real;

  function real pow2_real;
    input integer e;
    integer t;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (t = 0; t < e; t = t + 1)
          r = r * 2.0;
      end else begin
        for (t = 0; t < -e; t = t + 1)
          r = r / 2.0;
      end
      pow2_real = r;
    end
  endfunction

  function integer floor_real;
    input real x;
    integer t;
    begin
      t = $rtoi(x);
      if ((x < 0.0) && (x != t))
        floor_real = t - 1;
      else
        floor_real = t;
    end
  endfunction

  function integer round_even_real;
    input real x;
    integer flr;
    integer base;
    real frac;
    begin
      flr = floor_real(x);
      frac = x - flr;

      if (frac > 0.5) begin
        round_even_real = flr + 1;
      end else if (frac < 0.5) begin
        round_even_real = flr;
      end else begin
        base = flr;
        if ((base % 2) == 0)
          round_even_real = base;
        else
          round_even_real = base + 1;
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real value;
    real v;
    real norm;
    real frac_real;
    integer sign;
    integer exp_unbiased;
    integer exp_bits;
    integer frac_bits;
    integer rounded;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        if (value < 0.0) begin
          sign = 1;
          v = -value;
        end else begin
          sign = 0;
          v = value;
        end

        exp_unbiased = 0;
        norm = v;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_bits = exp_unbiased + 127;

        if (exp_bits <= 0) begin
          frac_real = v / pow2_real(-149);
          rounded = round_even_real(frac_real);

          if (rounded <= 0)
            real_to_fp32 = {sign[0], 31'b0};
          else if (rounded >= 8388608)
            real_to_fp32 = {sign[0], 8'd1, 23'd0};
          else
            real_to_fp32 = {sign[0], 8'd0, rounded[22:0]};
        end else if (exp_bits >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'd0};
        end else begin
          frac_real = (norm - 1.0) * pow2_real(23);
          rounded = round_even_real(frac_real);

          if (rounded >= 8388608) begin
            rounded = 0;
            exp_bits = exp_bits + 1;
          end

          if (exp_bits >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'd0};
          else begin
            frac_bits = rounded;
            real_to_fp32 = {sign[0], exp_bits[7:0], frac_bits[22:0]};
          end
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {NUM*FP_W{1'b0}};

    scale_a_real = $itor(scale_A) / pow2_real(SCALE_Q);
    scale_b_real = $itor(scale_B) / pow2_real(SCALE_Q);

    for (i = 0; i < NUM; i = i + 1) begin
      acc_s = C_acc[i*ACC_W +: ACC_W];
      out_real = $itor(acc_s) * scale_a_real * scale_b_real;
      C_fp[i*FP_W +: FP_W] = real_to_fp32(out_real);
    end
  end

endmodule