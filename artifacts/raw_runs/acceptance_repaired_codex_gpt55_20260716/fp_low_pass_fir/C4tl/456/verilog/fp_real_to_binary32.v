`timescale 1ns/1ps

module fp_real_to_binary32 (
    input real value,
    output reg [31:0] word
);

  reg sign_bit;
  integer exp_unbiased;
  integer exp_bits;
  integer mant_int;
  integer floor_int;
  integer rounded_int;

  real mag;
  real norm;
  real scaled;
  real frac;

  always @* begin
    sign_bit = 1'b0;
    mag = value;

    if (mag < 0.0) begin
      sign_bit = 1'b1;
      mag = -mag;
    end

    if (mag == 0.0) begin
      word = {sign_bit, 31'h00000000};
    end else begin
      norm = mag;
      exp_unbiased = 0;

      while (norm >= 2.0) begin
        norm = norm / 2.0;
        exp_unbiased = exp_unbiased + 1;
      end

      while (norm < 1.0) begin
        norm = norm * 2.0;
        exp_unbiased = exp_unbiased - 1;
      end

      exp_bits = exp_unbiased + 127;

      if (exp_bits >= 255) begin
        word = {sign_bit, 8'hfe, 23'h7fffff};
      end else if (exp_bits <= 0) begin
        scaled = mag / pow2_real(-149);
        rounded_int = round_nearest_even(scaled);

        if (rounded_int <= 0) begin
          word = {sign_bit, 31'h00000000};
        end else if (rounded_int >= 8388608) begin
          word = {sign_bit, 8'h01, 23'h000000};
        end else begin
          mant_int = rounded_int;
          word = {sign_bit, 8'h00, mant_int[22:0]};
        end
      end else begin
        scaled = (norm - 1.0) * 8388608.0;
        rounded_int = round_nearest_even(scaled);
        mant_int = rounded_int;

        if (mant_int >= 8388608) begin
          mant_int = 0;
          exp_bits = exp_bits + 1;
        end

        if (exp_bits >= 255) begin
          word = {sign_bit, 8'hfe, 23'h7fffff};
        end else begin
          word = {sign_bit, exp_bits[7:0], mant_int[22:0]};
        end
      end
    end
  end

  function integer round_nearest_even;
    input real x;
    integer base;
    real rem;
    begin
      base = $rtoi(x);
      rem = x - base;

      if (rem > 0.5) begin
        round_nearest_even = base + 1;
      end else if (rem < 0.5) begin
        round_nearest_even = base;
      end else begin
        if (base[0])
          round_nearest_even = base + 1;
        else
          round_nearest_even = base;
      end
    end
  endfunction

  function real pow2_real;
    input integer exp;
    integer j;
    real p;
    begin
      p = 1.0;

      if (exp >= 0) begin
        for (j = 0; j < exp; j = j + 1)
          p = p * 2.0;
      end else begin
        for (j = 0; j < -exp; j = j + 1)
          p = p / 2.0;
      end

      pow2_real = p;
    end
  endfunction

endmodule