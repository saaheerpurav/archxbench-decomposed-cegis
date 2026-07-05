`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEM_COUNT = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [ELEM_COUNT*ACC_W-1:0] C_acc,
  input  wire [SCALE_W-1:0] scale_A,
  input  wire [SCALE_W-1:0] scale_B,
  output reg  [ELEM_COUNT*FP_W-1:0] C_fp
);

  integer idx;
  integer acc_int;
  real scale_a_real;
  real scale_b_real;
  real value_real;

  function [31:0] real_to_fp32;
    input real x;
    reg sign;
    integer exp_unbiased;
    integer exp_biased;
    real ax;
    real norm;
    integer frac;
    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;

        exp_unbiased = 0;
        norm = ax;

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
          frac = $rtoi((norm - 1.0) * 8388608.0 + 0.5);

          if (frac >= 8388608) begin
            frac = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign, 8'hff, 23'b0};
          else
            real_to_fp32 = {sign, exp_biased[7:0], frac[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    scale_a_real = scale_A / (2.0 ** SCALE_Q);
    scale_b_real = scale_B / (2.0 ** SCALE_Q);
    C_fp = {ELEM_COUNT*FP_W{1'b0}};

    for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
      acc_int = $signed(C_acc[idx*ACC_W +: ACC_W]);
      value_real = acc_int * scale_a_real * scale_b_real;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(value_real);
    end
  end

endmodule