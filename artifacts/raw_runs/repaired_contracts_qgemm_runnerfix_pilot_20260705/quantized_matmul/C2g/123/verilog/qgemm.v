module qgemm #(
    parameter VLEN = 8,
    parameter K = 64,
    parameter FP_W = 32,
    parameter QBW = 8,
    parameter ACC_W = 32,
    parameter SCALE_W = 16,
    parameter SCALE_Q = 15
)(
    input clk,
    input rst,
    input start,
    input [VLEN*K*FP_W-1:0] A_fp,
    input [K*VLEN*FP_W-1:0] B_fp,
    input [SCALE_W-1:0] scale_A,
    input [SCALE_W-1:0] scale_B,
    input [QBW-1:0] zp_A,
    input [QBW-1:0] zp_B,
    output reg [VLEN*VLEN*FP_W-1:0] C_fp,
    output reg done
);

    integer i, j, kk;
    integer acc;
    integer aq, bq;
    integer za, zb;
    real sA, sB;
    real aval, bval, outval;

    function real fp32_to_real;
        input [31:0] bits;
        integer sign;
        integer exp;
        integer frac;
        real mant;
        real val;
        begin
            sign = bits[31];
            exp  = bits[30:23];
            frac = bits[22:0];

            if (exp == 0 && frac == 0) begin
                val = 0.0;
            end else if (exp == 0) begin
                mant = frac / 8388608.0;
                val = mant * pow2(-126);
            end else begin
                mant = 1.0 + frac / 8388608.0;
                val = mant * pow2(exp - 127);
            end

            fp32_to_real = sign ? -val : val;
        end
    endfunction

    function real pow2;
        input integer e;
        integer n;
        real r;
        begin
            r = 1.0;
            if (e >= 0) begin
                for (n = 0; n < e; n = n + 1)
                    r = r * 2.0;
            end else begin
                for (n = 0; n < -e; n = n + 1)
                    r = r / 2.0;
            end
            pow2 = r;
        end
    endfunction

    function integer round_even;
        input real x;
        integer floor_i;
        real frac;
        begin
            if (x >= 0.0) begin
                floor_i = x;
                frac = x - floor_i;
                if (frac > 0.5)
                    round_even = floor_i + 1;
                else if (frac < 0.5)
                    round_even = floor_i;
                else
                    round_even = (floor_i[0]) ? floor_i + 1 : floor_i;
            end else begin
                round_even = -round_even(-x);
            end
        end
    endfunction

    function integer signed_wrap;
        input integer x;
        integer modv;
        integer halfv;
        integer y;
        begin
            modv = (1 << QBW);
            halfv = (1 << (QBW - 1));
            y = x % modv;
            if (y < 0)
                y = y + modv;
            if (y >= halfv)
                y = y - modv;
            signed_wrap = y;
        end
    endfunction

    function [31:0] real_to_fp32;
        input real x;
        integer sign;
        integer exp_unbiased;
        integer exp_biased;
        integer frac;
        integer intpart;
        real ax;
        real norm;
        real scaled;
        real fracpart;
        begin
            if (x == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (x < 0.0);
                ax = sign ? -x : x;

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

                exp_biased = exp_unbiased + 127;

                if (exp_biased <= 0) begin
                    scaled = ax / pow2(-149);
                    intpart = round_even(scaled);
                    if (intpart <= 0)
                        real_to_fp32 = {sign[0], 31'b0};
                    else if (intpart >= 8388608)
                        real_to_fp32 = {sign[0], 8'd1, 23'b0};
                    else
                        real_to_fp32 = {sign[0], 8'd0, intpart[22:0]};
                end else if (exp_biased >= 255) begin
                    real_to_fp32 = {sign[0], 8'hff, 23'b0};
                end else begin
                    scaled = (norm - 1.0) * 8388608.0;
                    frac = round_even(scaled);

                    if (frac == 8388608) begin
                        frac = 0;
                        exp_biased = exp_biased + 1;
                    end

                    if (exp_biased >= 255)
                        real_to_fp32 = {sign[0], 8'hff, 23'b0};
                    else
                        real_to_fp32 = {sign[0], exp_biased[7:0], frac[22:0]};
                end
            end
        end
    endfunction

    function [31:0] get_A_bits;
        input integer idx;
        begin
            get_A_bits = A_fp[(VLEN*K-1-idx)*FP_W +: FP_W];
        end
    endfunction

    function [31:0] get_B_bits;
        input integer idx;
        begin
            get_B_bits = B_fp[(K*VLEN-1-idx)*FP_W +: FP_W];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            C_fp <= {VLEN*VLEN*FP_W{1'b0}};
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start) begin
                sA = scale_A / pow2(SCALE_Q);
                sB = scale_B / pow2(SCALE_Q);
                za = signed_wrap(zp_A);
                zb = signed_wrap(zp_B);

                for (i = 0; i < VLEN; i = i + 1) begin
                    for (j = 0; j < VLEN; j = j + 1) begin
                        acc = 0;

                        for (kk = 0; kk < K; kk = kk + 1) begin
                            aval = fp32_to_real(get_A_bits(i*K + kk));
                            bval = fp32_to_real(get_B_bits(kk*VLEN + j));

                            aq = signed_wrap(round_even(aval / sA) + za);
                            bq = signed_wrap(round_even(bval / sB) + zb);

                            acc = acc + (aq - za) * (bq - zb);
                        end

                        outval = sA * sB * acc;
                        C_fp[(i*VLEN+j)*FP_W +: FP_W] <= real_to_fp32(outval);
                    end
                end

                done <= 1'b1;
            end
        end
    end

endmodule