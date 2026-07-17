`timescale 1ns/1ps

module fp_real_math #(
    parameter OP = 0
) (
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] y
);

  function real fp32_to_real;
    input [31:0] x;
    integer sign;
    integer exp;
    integer frac;
    real mant;
    begin
      sign = x[31] ? -1 : 1;
      exp = x[30:23];
      frac = x[22:0];

      if (exp == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        fp32_to_real = sign * mant * (2.0 ** (-126));
      end else if (exp == 255) begin
        fp32_to_real = sign * (2.0 ** 128);
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = sign * mant * (2.0 ** (exp - 127));
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    real v;
    real scaled;
    real base;
    integer sign;
    integer exp;
    integer efield;
    integer frac;
    integer mant;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        v = sign ? -r : r;

        exp = 0;
        base = 1.0;

        if (v >= 2.0) begin
          while (v >= (base * 2.0)) begin
            base = base * 2.0;
            exp = exp + 1;
          end
        end else if (v < 1.0) begin
          while (v < base) begin
            base = base / 2.0;
            exp = exp - 1;
          end
        end

        efield = exp + 127;

        if (efield <= 0) begin
          scaled = v / (2.0 ** (-149));
          mant = $rtoi(scaled + 0.5);

          if (mant <= 0)
            real_to_fp32 = {sign[0], 31'h00000000};
          else if (mant >= 8388608)
            real_to_fp32 = {sign[0], 8'h01, 23'h000000};
          else
            real_to_fp32 = {sign[0], 8'h00, mant[22:0]};
        end else if (efield >= 255) begin
          real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
        end else begin
          scaled = (v / (2.0 ** exp) - 1.0) * 8388608.0;
          frac = $rtoi(scaled + 0.5);

          if (frac >= 8388608) begin
            frac = 0;
            efield = efield + 1;
          end

          if (efield >= 255)
            real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
          else
            real_to_fp32 = {sign[0], efield[7:0], frac[22:0]};
        end
      end
    end
  endfunction

  real ar;
  real br;
  real yr;

  always @* begin
    ar = fp32_to_real(a);
    br = fp32_to_real(b);

    if (OP == 0)
      yr = ar * br;
    else
      yr = ar + br;

    y = real_to_fp32(yr);
  end

endmodule