`timescale 1ns/1ps

module fp_bpf_mac_comb #(
    parameter TAP_CNT = 101
) (
    input wire [TAP_CNT*32-1:0] samples,
    input wire [TAP_CNT*32-1:0] coeffs,
    output reg [31:0] result
);
    integer i;
    reg [31:0] acc;
    reg [31:0] product;

    always @* begin
        acc = 32'h00000000;

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            product = fp32_mul(
                samples[(TAP_CNT-1-i)*32 +: 32],
                coeffs[i*32 +: 32]
            );
            acc = fp32_add(acc, product);
        end

        result = acc;
    end

    function [31:0] fp32_mul;
        input [31:0] a;
        input [31:0] b;
        real ar;
        real br;
        begin
            ar = fp32_to_real(a);
            br = fp32_to_real(b);
            fp32_mul = real_to_fp32(ar * br);
        end
    endfunction

    function [31:0] fp32_add;
        input [31:0] a;
        input [31:0] b;
        real ar;
        real br;
        begin
            ar = fp32_to_real(a);
            br = fp32_to_real(b);
            fp32_add = real_to_fp32(ar + br);
        end
    endfunction

    function real fp32_to_real;
        input [31:0] bits;
        integer exp;
        integer frac;
        real mant;
        real scale;
        begin
            exp = bits[30:23];
            frac = bits[22:0];

            if (exp == 0 && frac == 0) begin
                fp32_to_real = 0.0;
            end else begin
                if (exp == 0)
                    mant = frac / 8388608.0;
                else
                    mant = 1.0 + (frac / 8388608.0);

                scale = pow2_int((exp == 0) ? -126 : (exp - 127));
                fp32_to_real = mant * scale;

                if (bits[31])
                    fp32_to_real = -fp32_to_real;
            end
        end
    endfunction

    function real pow2_int;
        input integer e;
        integer k;
        real v;
        begin
            v = 1.0;

            if (e >= 0) begin
                for (k = 0; k < e; k = k + 1)
                    v = v * 2.0;
            end else begin
                for (k = 0; k < -e; k = k + 1)
                    v = v / 2.0;
            end

            pow2_int = v;
        end
    endfunction

    function [31:0] real_to_fp32;
        input real value;
        reg sign;
        real av;
        real norm;
        real frac_real;
        integer exp_unbiased;
        integer exp_field;
        integer mant;
        begin
            if (value == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (value < 0.0);
                av = sign ? -value : value;

                exp_unbiased = 0;
                norm = av;

                while (norm >= 2.0) begin
                    norm = norm / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end

                while (norm < 1.0) begin
                    norm = norm * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                exp_field = exp_unbiased + 127;

                if (exp_field >= 255) begin
                    real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
                end else if (exp_field <= 0) begin
                    frac_real = av / pow2_int(-149);
                    mant = frac_real + 0.5;

                    if (mant <= 0)
                        real_to_fp32 = 32'h00000000;
                    else if (mant >= 8388608)
                        real_to_fp32 = {sign, 8'h01, 23'h000000};
                    else
                        real_to_fp32 = {sign, 8'h00, mant[22:0]};
                end else begin
                    frac_real = (norm - 1.0) * 8388608.0;
                    mant = frac_real + 0.5;

                    if (mant >= 8388608) begin
                        mant = 0;
                        exp_field = exp_field + 1;
                    end

                    if (exp_field >= 255)
                        real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
                    else
                        real_to_fp32 = {sign, exp_field[7:0], mant[22:0]};
                end
            end
        end
    endfunction
endmodule