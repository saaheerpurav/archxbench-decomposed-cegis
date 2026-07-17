`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [VLEN*K*FP_W-1:0] A_fp,
  input  [K*VLEN*FP_W-1:0] B_fp,
  input  [SCALE_W-1:0] scale_A,
  input  [SCALE_W-1:0] scale_B,
  input  [QBW-1:0] zp_A,
  input  [QBW-1:0] zp_B,
  output reg [VLEN*K*QBW-1:0] A_q,
  output reg [K*VLEN*QBW-1:0] B_q
);

  integer i;
  reg signed [31:0] qi;
  real fp_val;
  real scale_val;

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    real mant;
    integer e;
    begin
      sign = bits[31];
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 8'h00) begin
        if (frac == 23'd0) begin
          fp32_to_real = 0.0;
        end else begin
          mant = frac / 8388608.0;
          fp32_to_real = mant * (2.0 ** -126);
        end
      end else if (exp == 8'hff) begin
        fp32_to_real = 0.0;
      end else begin
        e = exp - 127;
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant * (2.0 ** e);
      end

      if (sign)
        fp32_to_real = -fp32_to_real;
    end
  endfunction

  function integer round_nearest_even;
    input real x;
    integer base;
    real frac;
    begin
      if (x >= 0.0) begin
        base = x;
        frac = x - base;

        if (frac > 0.5)
          round_nearest_even = base + 1;
        else if (frac < 0.5)
          round_nearest_even = base;
        else if (base & 1)
          round_nearest_even = base + 1;
        else
          round_nearest_even = base;
      end else begin
        base = -x;
        frac = (-x) - base;

        if (frac > 0.5)
          round_nearest_even = -(base + 1);
        else if (frac < 0.5)
          round_nearest_even = -base;
        else if (base & 1)
          round_nearest_even = -(base + 1);
        else
          round_nearest_even = -base;
      end
    end
  endfunction

  always @* begin
    A_q = {VLEN*K*QBW{1'b0}};
    B_q = {K*VLEN*QBW{1'b0}};

    scale_val = $signed(scale_A) / (2.0 ** SCALE_Q);
    for (i = 0; i < VLEN*K; i = i + 1) begin
      fp_val = fp32_to_real(A_fp[VLEN*K*FP_W-1 - i*FP_W -: FP_W]);

      if (scale_val == 0.0)
        qi = $signed(zp_A);
      else
        qi = round_nearest_even(fp_val / scale_val) + $signed(zp_A);

      A_q[i*QBW +: QBW] = qi[QBW-1:0];
    end

    scale_val = $signed(scale_B) / (2.0 ** SCALE_Q);
    for (i = 0; i < K*VLEN; i = i + 1) begin
      fp_val = fp32_to_real(B_fp[K*VLEN*FP_W-1 - i*FP_W -: FP_W]);

      if (scale_val == 0.0)
        qi = $signed(zp_B);
      else
        qi = round_nearest_even(fp_val / scale_val) + $signed(zp_B);

      B_q[i*QBW +: QBW] = qi[QBW-1:0];
    end
  end

endmodule