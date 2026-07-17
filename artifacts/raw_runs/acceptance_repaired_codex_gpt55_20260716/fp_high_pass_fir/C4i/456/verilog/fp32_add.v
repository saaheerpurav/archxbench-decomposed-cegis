`timescale 1ns/1ps

module fp32_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);
    reg        sign_a, sign_b, sign_big, sign_small, sign_res;
    reg [7:0]  exp_a, exp_b, expa_eff, expb_eff, exp_big, exp_small, exp_res;
    reg [23:0] mant_a, mant_b, mant_big, mant_small;
    reg [55:0] big_m, small_m, norm_m;
    reg [56:0] add_m;
    reg [24:0] rounded;
    reg [8:0]  shift_amt;
    reg        guard_bit, round_bit, sticky_bit, inc;
    integer    k;

    function [55:0] shr_sticky56;
        input [55:0] v;
        input [8:0] sh;
        begin
            if (sh == 0) begin
                shr_sticky56 = v;
            end else if (sh >= 56) begin
                shr_sticky56 = {55'd0, |v};
            end else begin
                shr_sticky56 = v >> sh;
                shr_sticky56[0] = shr_sticky56[0] | |(v << (56 - sh));
            end
        end
    endfunction

    always @* begin
        sign_a = a[31];
        sign_b = b[31];
        exp_a  = a[30:23];
        exp_b  = b[30:23];

        y = 32'h00000000;
        norm_m = 56'd0;
        add_m = 57'd0;
        rounded = 25'd0;

        if (a[30:0] == 31'd0) begin
            y = b;
        end else if (b[30:0] == 31'd0) begin
            y = a;
        end else if (exp_a == 8'hff) begin
            y = {sign_a, 8'hfe, 23'h7fffff};
        end else if (exp_b == 8'hff) begin
            y = {sign_b, 8'hfe, 23'h7fffff};
        end else begin
            mant_a = (exp_a == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
            mant_b = (exp_b == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

            expa_eff = (exp_a == 8'd0) ? 8'd1 : exp_a;
            expb_eff = (exp_b == 8'd0) ? 8'd1 : exp_b;

            if ({expa_eff, mant_a} >= {expb_eff, mant_b}) begin
                sign_big   = sign_a;
                sign_small = sign_b;
                exp_big    = expa_eff;
                exp_small  = expb_eff;
                mant_big   = mant_a;
                mant_small = mant_b;
            end else begin
                sign_big   = sign_b;
                sign_small = sign_a;
                exp_big    = expb_eff;
                exp_small  = expa_eff;
                mant_big   = mant_b;
                mant_small = mant_a;
            end

            shift_amt = exp_big - exp_small;
            big_m     = {mant_big, 32'd0};
            small_m   = shr_sticky56({mant_small, 32'd0}, shift_amt);

            sign_res = sign_big;
            exp_res  = exp_big;

            if (sign_big == sign_small) begin
                add_m = {1'b0, big_m} + {1'b0, small_m};
                if (add_m[56]) begin
                    norm_m = add_m[56:1];
                    norm_m[0] = norm_m[0] | add_m[0];
                    exp_res = exp_big + 1'b1;
                end else begin
                    norm_m = add_m[55:0];
                end
            end else begin
                norm_m = big_m - small_m;
                if (norm_m == 56'd0) begin
                    sign_res = 1'b0;
                    exp_res  = 8'd0;
                end else begin
                    for (k = 0; k < 55; k = k + 1) begin
                        if (!norm_m[55] && exp_res > 8'd1) begin
                            norm_m  = norm_m << 1;
                            exp_res = exp_res - 1'b1;
                        end
                    end
                end
            end

            if (norm_m == 56'd0) begin
                y = 32'h00000000;
            end else begin
                guard_bit  = norm_m[31];
                round_bit  = norm_m[30];
                sticky_bit = |norm_m[29:0];
                inc        = guard_bit & (round_bit | sticky_bit | norm_m[32]);

                rounded = {1'b0, norm_m[55:32]} + inc;

                if (rounded[24]) begin
                    rounded = rounded >> 1;
                    exp_res = exp_res + 1'b1;
                end

                if (exp_res >= 8'hff)
                    y = {sign_res, 8'hfe, 23'h7fffff};
                else
                    y = {sign_res, exp_res, rounded[22:0]};
            end
        end
    end
endmodule