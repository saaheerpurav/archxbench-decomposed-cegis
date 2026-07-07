`timescale 1ns/1ps

module fp_float_add_comb (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] y
);
    function real fp32_to_real;
        input [31:0] bits;
        integer sign;
        integer exp;
        integer mant;
        integer k;
        real frac;
        real scale;
        begin
            sign = bits[31];
            exp  = bits[30:23];
            mant = bits[22:0];

            if (exp == 0 && mant == 0) begin
                fp32_to_real = 0.0;
            end else begin
                frac = (exp == 0) ? (mant / 8388608.0) : (1.0 + mant / 8388608.0);
                scale = 1.0;
                if (exp == 0) begin
                    for (k = 0; k < 126; k = k + 1) scale = scale / 2.0;
                end else if (exp >= 127) begin
                    for (k = 0; k < exp - 127; k = k + 1) scale = scale * 2.0;
                end else begin
                    for (k = 0; k < 127 - exp; k = k + 1) scale = scale / 2.0;
                end

                fp32_to_real = sign ? -(frac * scale) : (frac * scale);
            end
        end
    endfunction

    function [31:0] real_to_fp32;
        input real val;
        integer sign;
        integer exp;
        integer mant;
        real v;
        real frac;
        real scaled;
        begin
            if (val == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (val < 0.0);
                v = sign ? -val : val;
                exp = 127;

                while (v >= 2.0 && exp < 254) begin
                    v = v / 2.0;
                    exp = exp + 1;
                end

                while (v < 1.0 && exp > 1) begin
                    v = v * 2.0;
                    exp = exp - 1;
                end

                frac = v - 1.0;
                scaled = frac * 8388608.0;
                mant = scaled + 0.5;

                if (mant >= 8388608) begin
                    mant = 0;
                    exp = exp + 1;
                end

                if (exp >= 255)
                    real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
                else if (exp <= 0)
                    real_to_fp32 = 32'h00000000;
                else
                    real_to_fp32 = {sign[0], exp[7:0], mant[22:0]};
            end
        end
    endfunction

    assign y = real_to_fp32(fp32_to_real(a) + fp32_to_real(b));
endmodule