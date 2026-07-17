`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
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

  function integer msb_pos_64;
    input [63:0] value;
    integer b;
    begin
      msb_pos_64 = 0;
      for (b = 0; b < 64; b = b + 1) begin
        if (value[b])
          msb_pos_64 = b;
      end
    end
  endfunction

  function [31:0] fixed_q_to_fp32;
    input signed [63:0] fixed_value;
    input integer qbits;
    reg sign;
    reg [63:0] abs_value;
    integer msb;
    integer exp_unbiased;
    integer exp_biased;
    integer shift;
    reg [24:0] mant_ext;
    reg [63:0] shifted_out_mask;
    reg [63:0] shifted_out;
    reg guard;
    reg sticky;
    reg round_up;
    begin
      if (fixed_value == 0) begin
        fixed_q_to_fp32 = 32'h00000000;
      end else begin
        sign = fixed_value[63];
        abs_value = sign ? (~fixed_value + 64'd1) : fixed_value;

        msb = msb_pos_64(abs_value);
        exp_unbiased = msb - qbits;
        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          fixed_q_to_fp32 = {sign, 31'b0};
        end else if (exp_biased >= 255) begin
          fixed_q_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          shift = msb - 23;

          if (shift > 0) begin
            mant_ext = abs_value >> shift;

            shifted_out_mask = (64'd1 << shift) - 64'd1;
            shifted_out = abs_value & shifted_out_mask;
            guard = abs_value[shift-1];
            sticky = (shift > 1) ? |(shifted_out & ((64'd1 << (shift-1)) - 64'd1)) : 1'b0;

            round_up = guard && (sticky || mant_ext[0]);
            if (round_up)
              mant_ext = mant_ext + 25'd1;
          end else begin
            mant_ext = abs_value << (-shift);
          end

          if (mant_ext[24]) begin
            mant_ext = mant_ext >> 1;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            fixed_q_to_fp32 = {sign, 8'hff, 23'b0};
          else
            fixed_q_to_fp32 = {sign, exp_biased[7:0], mant_ext[22:0]};
        end
      end
    end
  endfunction

  integer idx;
  reg signed [ACC_W-1:0] acc_s;
  reg signed [63:0] scaled_product;

  always @* begin
    C_fp = {VLEN*VLEN*FP_W{1'b0}};

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      acc_s = C_acc[idx*ACC_W +: ACC_W];

      scaled_product =
          $signed(acc_s)
        * $signed({1'b0, scale_A})
        * $signed({1'b0, scale_B});

      C_fp[idx*FP_W +: FP_W] =
        fixed_q_to_fp32(scaled_product, 2*SCALE_Q);
    end
  end

endmodule