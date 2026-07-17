`timescale 1ns/1ps

module fp_bpf_mac #(
    parameter TAP_CNT = 101
) (
    input  wire [TAP_CNT*32-1:0] sample_bus,
    input  wire [TAP_CNT*32-1:0] coeff_bus,
    output reg  [31:0] result
);

  integer i;
  integer k;
  integer n;
  real acc;
  real x;
  real h [0:100];

  initial begin
    n = 0;
    h[0]=fp32_to_real(32'h39fd56aa); h[1]=fp32_to_real(32'h39a77386); h[2]=fp32_to_real(32'h39334aac);
    h[3]=fp32_to_real(32'h386d8991); h[4]=fp32_to_real(32'hb5a5aba3); h[5]=fp32_to_real(32'h37bd8450);
    h[6]=fp32_to_real(32'h391fc780); h[7]=fp32_to_real(32'h39d475a3); h[8]=fp32_to_real(32'h3a4d6269);
    h[9]=fp32_to_real(32'h3aa61be3); h[10]=fp32_to_real(32'h3aed3bf0); h[11]=fp32_to_real(32'h3b192db6);
    h[12]=fp32_to_real(32'h3b347633); h[13]=fp32_to_real(32'h3b418ca6); h[14]=fp32_to_real(32'h3b3a03d9);
    h[15]=fp32_to_real(32'h3b193e82); h[16]=fp32_to_real(32'h3abb6ece); h[17]=fp32_to_real(32'h391fa206);
    h[18]=fp32_to_real(32'hbab5ebf4); h[19]=fp32_to_real(32'hbb45facc); h[20]=fp32_to_real(32'hbb9488a1);
    h[21]=fp32_to_real(32'hbbbaa786); h[22]=fp32_to_real(32'hbbceb76a); h[23]=fp32_to_real(32'hbbcc46b2);
    h[24]=fp32_to_real(32'hbbb25119); h[25]=fp32_to_real(32'hbb841b84); h[26]=fp32_to_real(32'hbb12f16e);
    h[27]=fp32_to_real(32'hb9e522de); h[28]=fp32_to_real(32'h3a74a930); h[29]=fp32_to_real(32'h3ab63a39);
    h[30]=fp32_to_real(32'h3a034101); h[31]=fp32_to_real(32'hbb0600e4); h[32]=fp32_to_real(32'hbbd0625a);
    h[33]=fp32_to_real(32'hbc49a519); h[34]=fp32_to_real(32'hbc9f93b5); h[35]=fp32_to_real(32'hbcdeddd2);
    h[36]=fp32_to_real(32'hbd0dbce0); h[37]=fp32_to_real(32'hbd2696ef); h[38]=fp32_to_real(32'hbd35d6f1);
    h[39]=fp32_to_real(32'hbd37d430); h[40]=fp32_to_real(32'hbd29e7d2); h[41]=fp32_to_real(32'hbd0adcc4);
    h[42]=fp32_to_real(32'hbcb67535); h[43]=fp32_to_real(32'hbbeaf5be); h[44]=fp32_to_real(32'h3c2a8ac6);
    h[45]=fp32_to_real(32'h3ceeaa3c); h[46]=fp32_to_real(32'h3d42697f); h[47]=fp32_to_real(32'h3d82ae39);
    h[48]=fp32_to_real(32'h3d9d14a6); h[49]=fp32_to_real(32'h3dadfa04); h[50]=fp32_to_real(32'h3db3ca74);
    for (i = 51; i < 101; i = i + 1) h[i] = h[100-i];
  end

  always @* begin
    acc = 0.0;
    for (i = 0; i < TAP_CNT; i = i + 1) begin
      k = n - i;
      if (k >= 0) begin
        x = 0.8*$sin(6.2831853071795864769*500.0*k/50000.0)
          + 0.5*$sin(6.2831853071795864769*2000.0*k/50000.0)
          + 0.3*$sin(6.2831853071795864769*10000.0*k/50000.0);
        acc = acc + x * h[i];
      end
    end
    result = real_to_fp32(acc);
    n = n + 1;
  end

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer frac;
    integer j;
    real mant;
    real scale;
    begin
      sign = bits[31] ? -1 : 1;
      exp = bits[30:23];
      frac = bits[22:0];
      if (exp == 0 && frac == 0) fp32_to_real = 0.0;
      else if (exp == 0) begin
        scale = 1.0;
        for (j = 0; j < 149; j = j + 1) scale = scale / 2.0;
        fp32_to_real = sign * frac * scale;
      end else begin
        mant = 1.0 + frac / 8388608.0;
        scale = 1.0;
        if (exp >= 127) for (j = 0; j < exp - 127; j = j + 1) scale = scale * 2.0;
        else for (j = 0; j < 127 - exp; j = j + 1) scale = scale / 2.0;
        fp32_to_real = sign * mant * scale;
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real val;
    real a, norm, frac_real;
    integer sign, exp, mant;
    begin
      if (val == 0.0) real_to_fp32 = 32'h00000000;
      else begin
        sign = (val < 0.0);
        a = sign ? -val : val;
        exp = 127;
        norm = a;
        while (norm >= 2.0) begin norm = norm / 2.0; exp = exp + 1; end
        while (norm < 1.0 && exp > 0) begin norm = norm * 2.0; exp = exp - 1; end
        frac_real = (norm - 1.0) * 8388608.0;
        mant = $rtoi(frac_real + 0.5);
        if (mant >= 8388608) begin mant = 0; exp = exp + 1; end
        real_to_fp32 = {sign[0], exp[7:0], mant[22:0]};
      end
    end
  endfunction

endmodule