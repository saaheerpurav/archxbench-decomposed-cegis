`timescale 1ns/1ps

module qgemm_dequantizer #(
  parameter VLEN = 8,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [VLEN*VLEN*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0] scale_A,
  input  [SCALE_W-1:0] scale_B,
  output reg [VLEN*VLEN*FP_W-1:0] C_fp
);

  integer idx;
  integer bit_idx;
  reg neg_bit;
  reg [31:0] acc_bits;
  reg [31:0] acc_mag;
  reg [31:0] scale_prod;
  reg [63:0] scaled_mag;
  reg [31:0] fp_bits;

  function [31:0] mag_to_fp32;
    input neg_in;
    input [63:0] mag;
    integer scan;
    integer pos;
    integer bin_exp;
    integer shift_amt;
    integer biased_exp;
    reg [63:0] shifted;
    reg [63:0] rem;
    reg [63:0] half;
    reg [24:0] sig;
    reg [7:0] exp_bits;
    begin
      if (mag == 64'd0) begin
        mag_to_fp32 = 32'h00000000;
      end else begin
        pos = 0;
        for (scan = 0; scan < 64; scan = scan + 1) begin
          if (mag[scan])
            pos = scan;
        end

        bin_exp = pos - (2 * SCALE_Q);

        if (pos >= 23) begin
          shift_amt = pos - 23;
          shifted = mag >> shift_amt;
          sig = shifted[24:0];

          if (shift_amt != 0) begin
            rem = mag - (shifted << shift_amt);
            half = 64'd1 << (shift_amt - 1);
            if ((rem > half) || ((rem == half) && sig[0]))
              sig = sig + 1'b1;
          end
        end else begin
          sig = mag << (23 - pos);
        end

        if (sig[24]) begin
          sig = sig >> 1;
          bin_exp = bin_exp + 1;
        end

        biased_exp = bin_exp + 127;

        if (biased_exp >= 255) begin
          mag_to_fp32 = {neg_in, 8'hff, 23'b0};
        end else if (biased_exp <= 0) begin
          mag_to_fp32 = {neg_in, 31'b0};
        end else begin
          exp_bits = biased_exp;
          mag_to_fp32 = {neg_in, exp_bits, sig[22:0]};
        end
      end
    end
  endfunction

  always @(*) begin
    C_fp = {(VLEN*VLEN*FP_W){1'b0}};
    scale_prod = scale_A * scale_B;

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1)
        acc_bits[bit_idx] = C_acc[idx*32 + bit_idx];

      neg_bit = acc_bits[31];

      if (neg_bit)
        acc_mag = (~acc_bits) + 32'd1;
      else
        acc_mag = acc_bits;

      scaled_mag = acc_mag * scale_prod;
      fp_bits = mag_to_fp32(neg_bit, scaled_mag);

      for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1)
        C_fp[idx*32 + bit_idx] = fp_bits[bit_idx];
    end
  end

endmodule