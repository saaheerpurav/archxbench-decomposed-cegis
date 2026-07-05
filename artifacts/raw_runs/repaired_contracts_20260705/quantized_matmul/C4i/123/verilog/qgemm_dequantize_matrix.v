`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter VLEN = 8,
  parameter ELEMS = VLEN*VLEN,
  parameter COUNT = ELEMS,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [COUNT*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0] scale_A,
  input  [SCALE_W-1:0] scale_B,
  output [COUNT*FP_W-1:0] C_fp
);

  function [31:0] mag_q_to_fp32;
    input [63:0] mag;
    input sign_bit;
    integer b;
    integer msb;
    integer unbiased_exp;
    integer exp_field;
    integer rshift;
    integer lshift;
    integer frac_shift;
    reg [63:0] sig;
    reg [63:0] rem;
    reg [63:0] half;
    reg [63:0] base;
    reg [63:0] frac;
    begin
      if (mag == 64'd0) begin
        mag_q_to_fp32 = 32'h00000000;
      end else begin
        msb = 0;
        for (b = 0; b < 64; b = b + 1)
          if (mag[b])
            msb = b;

        unbiased_exp = msb - (2*SCALE_Q);

        if (unbiased_exp > 127) begin
          mag_q_to_fp32 = {sign_bit, 8'hff, 23'd0};
        end else if (unbiased_exp >= -126) begin
          if (msb > 23) begin
            rshift = msb - 23;
            sig = mag >> rshift;
            base = sig << rshift;
            rem = mag - base;
            half = 64'd1 << (rshift - 1);
            if ((rem > half) || ((rem == half) && sig[0]))
              sig = sig + 64'd1;
          end else begin
            lshift = 23 - msb;
            sig = mag << lshift;
          end

          if (sig[24]) begin
            sig = sig >> 1;
            unbiased_exp = unbiased_exp + 1;
          end

          if (unbiased_exp > 127) begin
            mag_q_to_fp32 = {sign_bit, 8'hff, 23'd0};
          end else begin
            exp_field = unbiased_exp + 127;
            mag_q_to_fp32 = {sign_bit, exp_field[7:0], sig[22:0]};
          end
        end else begin
          frac_shift = (2*SCALE_Q) - 149;

          if (frac_shift > 0) begin
            if (frac_shift >= 64) begin
              frac = 64'd0;
            end else begin
              frac = mag >> frac_shift;
              base = frac << frac_shift;
              rem = mag - base;
              half = 64'd1 << (frac_shift - 1);
              if ((rem > half) || ((rem == half) && frac[0]))
                frac = frac + 64'd1;
            end
          end else begin
            frac = mag << (149 - (2*SCALE_Q));
          end

          if (frac >= 64'd8388608)
            mag_q_to_fp32 = {sign_bit, 8'd1, 23'd0};
          else
            mag_q_to_fp32 = {sign_bit, 8'd0, frac[22:0]};
        end
      end
    end
  endfunction

  function [31:0] dequant_one;
    input [31:0] acc_bits;
    input [15:0] sA;
    input [15:0] sB;
    reg sign_bit;
    reg [31:0] acc_abs;
    reg [63:0] prod;
    begin
      sign_bit = acc_bits[31];
      acc_abs = sign_bit ? (~acc_bits + 32'd1) : acc_bits;
      prod = {32'd0, acc_abs} * {48'd0, sA};
      prod = prod * {48'd0, sB};
      dequant_one = mag_q_to_fp32(prod, sign_bit);
    end
  endfunction

  genvar g;
  generate
    for (g = 0; g < COUNT; g = g + 1) begin : gen_dequant
      assign C_fp[g*FP_W +: FP_W] =
        dequant_one(C_acc[g*ACC_W +: ACC_W], scale_A[15:0], scale_B[15:0]);
    end
  endgenerate

endmodule