`timescale 1ns/1ps

module fp_float32_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);

    reg        sign_a, sign_b, sign_r;
    reg [7:0]  exp_a, exp_b;
    reg [22:0] frac_a, frac_b;

    reg [7:0]  exp_eff_a, exp_eff_b;
    reg [7:0]  exp_r;

    reg [26:0] mant_a, mant_b;
    reg [26:0] mant_big, mant_small;
    reg        sign_big, sign_small;
    reg [7:0]  exp_big, exp_small;

    reg [27:0] sum;
    reg [26:0] mant_r;

    reg [23:0] mant_pre;
    reg [24:0] mant_round;
    reg        guard_bit, round_bit, sticky_bit;
    reg        round_inc;

    integer shift_amt;
    integer i;

    function [26:0] shift_right_jam;
        input [26:0] value;
        input integer sh;
        integer j;
        reg sticky;
        begin
            if (sh <= 0) begin
                shift_right_jam = value;
            end else if (sh >= 27) begin
                shift_right_jam = {|value};
            end else begin
                sticky = 1'b0;
                for (j = 0; j < sh; j = j + 1)
                    sticky = sticky | value[j];
                shift_right_jam = (value >> sh);
                shift_right_jam[0] = shift_right_jam[0] | sticky;
            end
        end
    endfunction

    always @(*) begin
        sign_a = a[31];
        exp_a  = a[30:23];
        frac_a = a[22:0];

        sign_b = b[31];
        exp_b  = b[30:23];
        frac_b = b[22:0];

        y = 32'h00000000;

        if (exp_a == 8'hff) begin
            if (frac_a != 0)
                y = 32'h7fc00000;
            else if ((exp_b == 8'hff) && (frac_b == 0) && (sign_a != sign_b))
                y = 32'h7fc00000;
            else
                y = a;
        end else if (exp_b == 8'hff) begin
            if (frac_b != 0)
                y = 32'h7fc00000;
            else
                y = b;
        end else if (a[30:0] == 31'd0) begin
            y = b;
        end else if (b[30:0] == 31'd0) begin
            y = a;
        end else begin
            exp_eff_a = (exp_a == 0) ? 8'd1 : exp_a;
            exp_eff_b = (exp_b == 0) ? 8'd1 : exp_b;

            mant_a = {exp_a != 0, frac_a, 3'b000};
            mant_b = {exp_b != 0, frac_b, 3'b000};

            if ((exp_eff_a > exp_eff_b) ||
                ((exp_eff_a == exp_eff_b) && (mant_a >= mant_b))) begin
                mant_big   = mant_a;
                mant_small = mant_b;
                sign_big   = sign_a;
                sign_small = sign_b;
                exp_big    = exp_eff_a;
                exp_small  = exp_eff_b;
            end else begin
                mant_big   = mant_b;
                mant_small = mant_a;
                sign_big   = sign_b;
                sign_small = sign_a;
                exp_big    = exp_eff_b;
                exp_small  = exp_eff_a;
            end

            shift_amt = exp_big - exp_small;
            mant_small = shift_right_jam(mant_small, shift_amt);

            sign_r = sign_big;
            exp_r  = exp_big;

            if (sign_big == sign_small) begin
                sum = {1'b0, mant_big} + {1'b0, mant_small};

                if (sum[27]) begin
                    mant_r = shift_right_jam(sum[27:1], 1);
                    exp_r = exp_r + 1'b1;
                end else begin
                    mant_r = sum[26:0];
                end
            end else begin
                sum = {1'b0, mant_big} - {1'b0, mant_small};
                mant_r = sum[26:0];

                if (mant_r == 27'd0) begin
                    y = 32'h00000000;
                end else begin
                    for (i = 0; i < 26; i = i + 1) begin
                        if ((mant_r[26] == 1'b0) && (exp_r > 8'd1)) begin
                            mant_r = mant_r << 1;
                            exp_r = exp_r - 1'b1;
                        end
                    end
                end
            end

            if (mant_r != 27'd0) begin
                guard_bit  = mant_r[2];
                round_bit  = mant_r[1];
                sticky_bit = mant_r[0];
                mant_pre   = mant_r[26:3];

                round_inc  = guard_bit & (round_bit | sticky_bit | mant_pre[0]);
                mant_round = {1'b0, mant_pre} + round_inc;

                if (mant_round[24]) begin
                    mant_round = mant_round >> 1;
                    exp_r = exp_r + 1'b1;
                end

                if (exp_r >= 8'hff) begin
                    y = {sign_r, 8'hff, 23'd0};
                end else if ((exp_r == 8'd1) && (mant_round[23] == 1'b0)) begin
                    y = {sign_r, 8'd0, mant_round[22:0]};
                end else begin
                    y = {sign_r, exp_r, mant_round[22:0]};
                end
            end
        end
    end

endmodule