`timescale 1ns/1ps

module fp_highpass_mac #(
    parameter TAP_CNT = 31
) (
    input  [TAP_CNT*32-1:0] samples_flat,
    input  [TAP_CNT*32-1:0] coeffs_flat,
    output [31:0]           result
);

    integer k;
    reg [31:0] acc;

    function [31:0] fp32_mul;
        input [31:0] a;
        input [31:0] b;

        reg        sign;
        reg [7:0]  exp_a, exp_b;
        reg [23:0] mant_a, mant_b;
        reg [47:0] prod;
        reg signed [10:0] exp_r;
        reg [24:0] mant_ext;
        reg        round_bit, sticky_bit;
        begin
            if (a[30:0] == 31'd0 || b[30:0] == 31'd0) begin
                fp32_mul = 32'h00000000;
            end else begin
                sign   = a[31] ^ b[31];
                exp_a  = a[30:23];
                exp_b  = b[30:23];
                mant_a = (exp_a == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
                mant_b = (exp_b == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

                prod  = mant_a * mant_b;
                exp_r = $signed({3'b000, exp_a}) + $signed({3'b000, exp_b}) - 11'sd127;

                if (prod[47]) begin
                    mant_ext   = {1'b0, prod[47:24]};
                    round_bit  = prod[23];
                    sticky_bit = |prod[22:0];
                    exp_r      = exp_r + 11'sd1;
                end else begin
                    mant_ext   = {1'b0, prod[46:23]};
                    round_bit  = prod[22];
                    sticky_bit = |prod[21:0];
                end

                mant_ext = mant_ext + (round_bit & (sticky_bit | mant_ext[0]));

                if (mant_ext[24]) begin
                    mant_ext = mant_ext >> 1;
                    exp_r    = exp_r + 11'sd1;
                end

                if (exp_r <= 0)
                    fp32_mul = 32'h00000000;
                else if (exp_r >= 255)
                    fp32_mul = {sign, 8'hff, 23'd0};
                else
                    fp32_mul = {sign, exp_r[7:0], mant_ext[22:0]};
            end
        end
    endfunction

    function [31:0] fp32_add;
        input [31:0] a;
        input [31:0] b;

        reg        sign_a, sign_b, sign_r;
        reg [7:0]  exp_a, exp_b, exp_r;
        reg [27:0] mant_a, mant_b;
        reg [28:0] mant_sum;
        reg [27:0] mant_norm;
        reg [24:0] rounded;
        integer shift;
        integer n;
        begin
            if (a[30:0] == 31'd0) begin
                fp32_add = b;
            end else if (b[30:0] == 31'd0) begin
                fp32_add = a;
            end else begin
                sign_a = a[31];
                sign_b = b[31];
                exp_a  = a[30:23];
                exp_b  = b[30:23];

                mant_a = {1'b1, a[22:0], 4'b0000};
                mant_b = {1'b1, b[22:0], 4'b0000};

                if (exp_a >= exp_b) begin
                    shift = exp_a - exp_b;
                    exp_r = exp_a;
                    mant_b = (shift >= 28) ? 28'd0 : (mant_b >> shift);
                end else begin
                    shift = exp_b - exp_a;
                    exp_r = exp_b;
                    mant_a = (shift >= 28) ? 28'd0 : (mant_a >> shift);
                end

                if (sign_a == sign_b) begin
                    mant_sum = {1'b0, mant_a} + {1'b0, mant_b};
                    sign_r = sign_a;

                    if (mant_sum[28]) begin
                        mant_norm = mant_sum[28:1];
                        exp_r     = exp_r + 8'd1;
                    end else begin
                        mant_norm = mant_sum[27:0];
                    end
                end else begin
                    if (mant_a >= mant_b) begin
                        mant_norm = mant_a - mant_b;
                        sign_r = sign_a;
                    end else begin
                        mant_norm = mant_b - mant_a;
                        sign_r = sign_b;
                    end

                    if (mant_norm == 28'd0) begin
                        exp_r = 8'd0;
                    end else begin
                        for (n = 0; n < 27; n = n + 1) begin
                            if (mant_norm[27] == 1'b0 && exp_r > 8'd1) begin
                                mant_norm = mant_norm << 1;
                                exp_r = exp_r - 8'd1;
                            end
                        end
                    end
                end

                if (mant_norm == 28'd0 || exp_r == 8'd0) begin
                    fp32_add = 32'h00000000;
                end else begin
                    rounded = {1'b0, mant_norm[27:4]} +
                              (mant_norm[3] & (|mant_norm[2:0] | mant_norm[4]));

                    if (rounded[24])
                        fp32_add = {sign_r, exp_r + 8'd1, rounded[22:0]};
                    else
                        fp32_add = {sign_r, exp_r, rounded[22:0]};
                end
            end
        end
    endfunction

    always @* begin
        acc = 32'h00000000;
        for (k = 0; k < TAP_CNT; k = k + 1) begin
            acc = fp32_add(
                acc,
                fp32_mul(
                    samples_flat[k*32 +: 32],
                    coeffs_flat[k*32 +: 32]
                )
            );
        end
    end

    assign result = acc;

endmodule