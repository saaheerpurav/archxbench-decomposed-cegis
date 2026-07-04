`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter COUNT   = 64,
  parameter FP_W    = 32,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [COUNT*ACC_W-1:0]    C_acc,
  input  [SCALE_W-1:0]        scale_A,
  input  [SCALE_W-1:0]        scale_B,
  output reg [COUNT*FP_W-1:0] C_fp
);

  integer i;
  integer src_idx;
  integer acc_signed;
  real scale_real_A;
  real scale_real_B;
  real out_real;

  function [31:0] real_to_fp32;
    input real x;

    integer sign;
    integer exp_unbiased;
    integer exp_raw;
    integer frac_int;
    real ax;
    real norm;
    real frac_real;

    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        if (x < 0.0) begin
          sign = 1;
          ax = -x;
        end else begin
          sign = 0;
          ax = x;
        end

        if (ax >= 3.4028234663852886e38) begin
          real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
        end else begin
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

          exp_raw = exp_unbiased + 127;

          if (exp_raw <= 0) begin
            real_to_fp32 = {sign[0], 31'h00000000};
          end else if (exp_raw >= 255) begin
            real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
          end else begin
            frac_real = (norm - 1.0) * 8388608.0;
            frac_int = $rtoi(frac_real + 0.5);

            if (frac_int >= 8388608) begin
              frac_int = 0;
              exp_raw = exp_raw + 1;

              if (exp_raw >= 255) begin
                exp_raw = 254;
                frac_int = 8388607;
              end
            end

            real_to_fp32 = {sign[0], exp_raw[7:0], frac_int[22:0]};
          end
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {COUNT*FP_W{1'b0}};

    scale_real_A = scale_A / (2.0 ** SCALE_Q);
    scale_real_B = scale_B / (2.0 ** SCALE_Q);

    for (i = 0; i < COUNT; i = i + 1) begin
      src_idx = COUNT - 1 - i;
      acc_signed = $signed(C_acc[src_idx*ACC_W +: ACC_W]);
      out_real = acc_signed * scale_real_A * scale_real_B;
      C_fp[i*FP_W +: FP_W] = real_to_fp32(out_real);
    end
  end

endmodule