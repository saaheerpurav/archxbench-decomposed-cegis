`timescale 1ns/1ps

module qgemm_dequantize_tile #(
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
  reg signed [ACC_W-1:0] acc_word;

  function [31:0] acc_scale_to_fp32;
    input signed [ACC_W-1:0] acc;
    input [SCALE_W-1:0] sca;
    input [SCALE_W-1:0] scb;

    reg sign;
    reg [ACC_W-1:0] acc_mag;
    reg [127:0] mag;
    reg [127:0] prod;
    reg [127:0] mant_full;
    integer msb;
    integer p;
    integer shift;
    integer exp_unbiased;
    integer exp_biased;
    reg guard;
    reg sticky;
    begin
      if ((acc == 0) || (sca == 0) || (scb == 0)) begin
        acc_scale_to_fp32 = 32'h00000000;
      end else begin
        sign = acc[ACC_W-1];
        acc_mag = sign ? (~acc + {{(ACC_W-1){1'b0}}, 1'b1}) : acc[ACC_W-1:0];
        mag = {{(128-ACC_W){1'b0}}, acc_mag};

        prod = mag * sca * scb;

        msb = 0;
        for (p = 0; p < 128; p = p + 1) begin
          if (prod[p])
            msb = p;
        end

        exp_unbiased = msb - (2 * SCALE_Q);
        exp_biased = exp_unbiased + 127;

        if (exp_unbiased < -126) begin
          acc_scale_to_fp32 = {sign, 31'd0};
        end else if (exp_unbiased > 127) begin
          acc_scale_to_fp32 = {sign, 8'hff, 23'd0};
        end else begin
          if (msb > 23) begin
            shift = msb - 23;
            mant_full = prod >> shift;

            guard = prod[shift-1];
            sticky = 1'b0;
            for (p = 0; p < shift-1; p = p + 1) begin
              if (prod[p])
                sticky = 1'b1;
            end

            if (guard && (sticky || mant_full[0]))
              mant_full = mant_full + 1'b1;
          end else begin
            mant_full = prod << (23 - msb);
          end

          if (mant_full[24]) begin
            mant_full = mant_full >> 1;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            acc_scale_to_fp32 = {sign, 8'hff, 23'd0};
          else
            acc_scale_to_fp32 = {sign, exp_biased[7:0], mant_full[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {(VLEN*VLEN*FP_W){1'b0}};
    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      acc_word = C_acc[idx*ACC_W +: ACC_W];
      C_fp[idx*FP_W +: FP_W] = acc_scale_to_fp32(acc_word, scale_A, scale_B);
    end
  end

endmodule