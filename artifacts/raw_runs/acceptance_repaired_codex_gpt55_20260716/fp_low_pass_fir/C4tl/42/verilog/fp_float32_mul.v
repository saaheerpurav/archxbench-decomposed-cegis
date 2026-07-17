`timescale 1ns/1ps

module fp_float32_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);
    reg        sign;
    reg [7:0]  exp_a, exp_b;
    reg [22:0] frac_a, frac_b;
    reg [23:0] sig_a, sig_b;
    reg signed [11:0] exp_sum;
    reg signed [11:0] exp_norm;
    reg signed [11:0] exp_tmp;
    reg [7:0]  exp_out;

    reg [47:0] product;
    reg [47:0] norm_product;
    reg [47:0] lost_mask;
    reg        lost_sticky;

    integer msb;
    integer sh;

    reg [23:0] mant24;
    reg [24:0] rounded_mant;
    reg        guard_bit;
    reg        round_bit;
    reg        sticky_bit;
    reg        inc;

    reg [47:0] sub_shifted;
    reg [47:0] sub_lost_mask;
    reg        sub_lost_sticky;
    integer    sub_shift;

    reg [22:0] sub_frac;
    reg [23:0] sub_rounded;

    always @(*) begin
        sign   = a[31] ^ b[31];
        exp_a  = a[30:23];
        exp_b  = b[30:23];
        frac_a = a[22:0];
        frac_b = b[22:0];

        y = 32'h00000000;

        if ((exp_a == 8'hff && frac_a != 23'd0) ||
            (exp_b == 8'hff && frac_b != 23'd0)) begin
            y = 32'h7fc00000;
        end else if ((exp_a == 8'hff && b[30:0] == 31'd0) ||
                     (exp_b == 8'hff && a[30:0] == 31'd0)) begin
            y = 32'h7fc00000;
        end else if (exp_a == 8'hff || exp_b == 8'hff) begin
            y = {sign, 8'hfe, 23'h7fffff};
        end else if (a[30:0] == 31'd0 || b[30:0] == 31'd0) begin
            y = {sign, 31'd0};
        end else begin
            sig_a = (exp_a == 8'd0) ? {1'b0, frac_a} : {1'b1, frac_a};
            sig_b = (exp_b == 8'd0) ? {1'b0, frac_b} : {1'b1, frac_b};

            exp_sum = ((exp_a == 8'd0) ? -12'sd126 : $signed({4'd0, exp_a}) - 12'sd127) +
                      ((exp_b == 8'd0) ? -12'sd126 : $signed({4'd0, exp_b}) - 12'sd127);

            product = sig_a * sig_b;

            msb = 47;
            while (msb > 0 && product[msb] == 1'b0)
                msb = msb - 1;

            exp_norm = exp_sum + msb - 46;
            lost_sticky = 1'b0;

            if (msb > 46) begin
                sh = msb - 46;
                lost_mask = (48'h1 << sh) - 48'h1;
                lost_sticky = |(product & lost_mask);
                norm_product = product >> sh;
            end else begin
                sh = 46 - msb;
                norm_product = product << sh;
            end

            if (exp_norm > 12'sd127) begin
                y = {sign, 8'hfe, 23'h7fffff};
            end else if (exp_norm >= -12'sd126) begin
                mant24     = norm_product[46:23];
                guard_bit  = norm_product[22];
                round_bit  = norm_product[21];
                sticky_bit = |norm_product[20:0] | lost_sticky;
                inc        = guard_bit;

                rounded_mant = {1'b0, mant24} + inc;

                if (rounded_mant[24]) begin
                    if (exp_norm == 12'sd127) begin
                        y = {sign, 8'hfe, 23'h7fffff};
                    end else begin
                        exp_tmp = exp_norm + 12'sd128;
                        exp_out = exp_tmp[7:0];
                        y = {sign, exp_out, 23'd0};
                    end
                end else begin
                    exp_tmp = exp_norm + 12'sd127;
                    exp_out = exp_tmp[7:0];
                    y = {sign, exp_out, rounded_mant[22:0]};
                end
            end else begin
                sub_shift = -126 - exp_norm;

                if (sub_shift > 47) begin
                    y = {sign, 31'd0};
                end else begin
                    sub_lost_mask = (48'h1 << sub_shift) - 48'h1;
                    sub_lost_sticky = |(norm_product & sub_lost_mask) | lost_sticky;
                    sub_shifted = norm_product >> sub_shift;

                    sub_frac   = sub_shifted[45:23];
                    guard_bit  = sub_shifted[22];
                    round_bit  = sub_shifted[21];
                    sticky_bit = |sub_shifted[20:0] | sub_lost_sticky;
                    inc        = guard_bit;

                    sub_rounded = {1'b0, sub_frac} + inc;

                    if (sub_rounded[23])
                        y = {sign, 8'd1, 23'd0};
                    else
                        y = {sign, 8'd0, sub_rounded[22:0]};
                end
            end
        end
    end
endmodule