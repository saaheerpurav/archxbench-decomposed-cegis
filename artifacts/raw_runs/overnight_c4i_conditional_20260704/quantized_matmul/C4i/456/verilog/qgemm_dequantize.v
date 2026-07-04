`timescale 1ns/1ps

module qgemm_dequantize #(
  parameter VLEN    = 8,
  parameter FP_W    = 32,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [VLEN*VLEN*ACC_W-1:0] C_acc,
  input  wire [SCALE_W-1:0]         scale_A,
  input  wire [SCALE_W-1:0]         scale_B,
  output reg  [VLEN*VLEN*FP_W-1:0]  C_fp
);

  localparam FRAC_BITS = 2*SCALE_Q;
  localparam PROD_W    = ACC_W + 2*SCALE_W;

  integer idx;
  reg signed [ACC_W-1:0] acc_s;
  reg signed [PROD_W-1:0] acc_ext;
  reg signed [PROD_W-1:0] scale_a_ext;
  reg signed [PROD_W-1:0] scale_b_ext;
  reg signed [PROD_W-1:0] acc_scale_prod;
  reg signed [PROD_W-1:0] prod_q30;

  function [31:0] q30_to_fp32;
    input signed [PROD_W-1:0] val;

    reg sign;
    reg [PROD_W-1:0] abs_val;
    reg [23:0] sig;
    reg [24:0] rounded_sig;
    reg guard;
    reg sticky;
    integer msb;
    integer shift;
    integer exp_field;
    integer i;

    begin
      if (val == 0) begin
        q30_to_fp32 = 32'h00000000;
      end else begin
        sign = val[PROD_W-1];
        abs_val = sign ? -val : val;

        msb = 0;
        for (i = 0; i < PROD_W; i = i + 1)
          if (abs_val[i])
            msb = i;

        exp_field = msb - FRAC_BITS + 127;

        if (exp_field <= 0) begin
          q30_to_fp32 = {sign, 31'b0};
        end else if (exp_field >= 255) begin
          q30_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          guard = 1'b0;
          sticky = 1'b0;

          if (msb >= 23) begin
            shift = msb - 23;
            sig = abs_val >> shift;

            if (shift > 0) begin
              guard = abs_val[shift-1];
              for (i = 0; i < shift-1; i = i + 1)
                if (abs_val[i])
                  sticky = 1'b1;
            end
          end else begin
            sig = abs_val << (23 - msb);
          end

          rounded_sig = {1'b0, sig};

          if (guard && (sticky || sig[0]))
            rounded_sig = rounded_sig + 1'b1;

          if (rounded_sig[24]) begin
            rounded_sig = rounded_sig >> 1;
            exp_field = exp_field + 1;
          end

          if (exp_field >= 255)
            q30_to_fp32 = {sign, 8'hff, 23'b0};
          else
            q30_to_fp32 = {sign, exp_field[7:0], rounded_sig[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {VLEN*VLEN*FP_W{1'b0}};

    scale_a_ext = {{(PROD_W-SCALE_W){1'b0}}, scale_A};
    scale_b_ext = {{(PROD_W-SCALE_W){1'b0}}, scale_B};

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      acc_s = C_acc[idx*ACC_W +: ACC_W];
      acc_ext = {{(PROD_W-ACC_W){acc_s[ACC_W-1]}}, acc_s};

      acc_scale_prod = acc_ext * scale_a_ext;
      prod_q30       = acc_scale_prod * scale_b_ext;

      C_fp[idx*FP_W +: FP_W] = q30_to_fp32(prod_q30);
    end
  end

endmodule