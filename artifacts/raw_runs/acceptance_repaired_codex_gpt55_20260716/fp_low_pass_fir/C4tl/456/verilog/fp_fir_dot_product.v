`timescale 1ns/1ps

module fp_fir_dot_product #(
    parameter TAP_CNT = 101
) (
    input  wire [TAP_CNT*32-1:0] sample_bus,
    input  wire [TAP_CNT*32-1:0] coeff_bus,
    output wire [31:0] result
);

  real acc;
  integer i;

  always @* begin
    acc = 0.0;
    for (i = 0; i < TAP_CNT; i = i + 1) begin
      acc = acc + binary32_to_real(sample_bus[i*32 +: 32])
                * binary32_to_real(coeff_bus[i*32 +: 32]);
    end
  end

  fp_real_to_binary32 result_conv (
    .value(acc),
    .word(result)
  );

  function real pow2_real;
    input integer exp;
    integer j;
    real value;
    begin
      value = 1.0;

      if (exp >= 0) begin
        for (j = 0; j < exp; j = j + 1)
          value = value * 2.0;
      end else begin
        for (j = 0; j < -exp; j = j + 1)
          value = value / 2.0;
      end

      pow2_real = value;
    end
  endfunction

  function real binary32_to_real;
    input [31:0] word;
    reg sign_bit;
    integer exp_bits;
    integer frac_bits;
    real frac_value;
    real magnitude;
    begin
      sign_bit = word[31];
      exp_bits = word[30:23];
      frac_bits = word[22:0];

      if (exp_bits == 0) begin
        if (frac_bits == 0) begin
          magnitude = 0.0;
        end else begin
          frac_value = frac_bits;
          magnitude = (frac_value / 8388608.0) * pow2_real(-126);
        end
      end else begin
        frac_value = frac_bits;
        magnitude = (1.0 + frac_value / 8388608.0) * pow2_real(exp_bits - 127);
      end

      if (sign_bit)
        binary32_to_real = -magnitude;
      else
        binary32_to_real = magnitude;
    end
  endfunction

endmodule