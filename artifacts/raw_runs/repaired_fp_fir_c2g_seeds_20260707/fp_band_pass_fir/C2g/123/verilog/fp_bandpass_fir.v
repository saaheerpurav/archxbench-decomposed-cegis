`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    localparam CENTER_DELAY = (TAP_CNT - 1) / 2;

    integer i;
    reg [31:0] samples [0:TAP_CNT-1];
    reg [31:0] out_reg;
    reg [CENTER_DELAY:0] valid_pipe;
    reg [CENTER_DELAY:0] tail_pipe;
    reg valid_in_d;

    assign valid_out = valid_pipe[CENTER_DELAY] | tail_pipe[CENTER_DELAY];
    assign data_out  = out_reg;

    function real fp32_to_real;
        input [31:0] f;
        reg sign;
        integer exp;
        integer frac;
        real mant;
        begin
            sign = f[31];
            exp  = f[30:23];
            frac = f[22:0];

            if (exp == 0 && frac == 0) begin
                fp32_to_real = 0.0;
            end else if (exp == 0) begin
                mant = frac / 8388608.0;
                fp32_to_real = mant * (2.0 ** (-126));
                if (sign) fp32_to_real = -fp32_to_real;
            end else begin
                mant = 1.0 + frac / 8388608.0;
                fp32_to_real = mant * (2.0 ** (exp - 127));
                if (sign) fp32_to_real = -fp32_to_real;
            end
        end
    endfunction

    function [31:0] real_to_fp32;
        input real r;
        reg sign;
        integer exp;
        integer frac;
        real v;
        begin
            if (r == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (r < 0.0);
                v = sign ? -r : r;

                exp = 0;
                while (v >= 2.0) begin
                    v = v / 2.0;
                    exp = exp + 1;
                end
                while (v < 1.0) begin
                    v = v * 2.0;
                    exp = exp - 1;
                end

                frac = ((v - 1.0) * 8388608.0) + 0.5;
                if (frac >= 8388608) begin
                    frac = 0;
                    exp = exp + 1;
                end

                exp = exp + 127;

                if (exp <= 0)
                    real_to_fp32 = 32'h00000000;
                else if (exp >= 255)
                    real_to_fp32 = {sign, 8'hff, 23'h000000};
                else
                    real_to_fp32 = {sign, exp[7:0], frac[22:0]};
            end
        end
    endfunction

    function [31:0] coeff;
        input integer idx;
        begin
            case (idx)
                0:  coeff = 32'hbb306eeb;
                1:  coeff = 32'hbb75b0a5;
                2:  coeff = 32'hbbbb295a;
                3:  coeff = 32'hbc0bd069;
                4:  coeff = 32'hbc3f59f2;
                5:  coeff = 32'hbc6787ee;
                6:  coeff = 32'hbc6e9b06;
                7:  coeff = 32'hbc3ecbfc;
                8:  coeff = 32'hbb90d9b1;
                9:  coeff = 32'h3bf10411;
                10: coeff = 32'h3cbc752e;
                11: coeff = 32'h3d27a476;
                12: coeff = 32'h3d70effe;
                13: coeff = 32'h3d97bf5e;
                14: coeff = 32'h3dacccb2;
                15: coeff = 32'h3db43958;
                16: coeff = 32'h3dacccb2;
                17: coeff = 32'h3d97bf5e;
                18: coeff = 32'h3d70effe;
                19: coeff = 32'h3d27a476;
                20: coeff = 32'h3cbc752e;
                21: coeff = 32'h3bf10411;
                22: coeff = 32'hbb90d9b1;
                23: coeff = 32'hbc3ecbfc;
                24: coeff = 32'hbc6e9b06;
                25: coeff = 32'hbc6787ee;
                26: coeff = 32'hbc3f59f2;
                27: coeff = 32'hbc0bd069;
                28: coeff = 32'hbbbb295a;
                29: coeff = 32'hbb75b0a5;
                30: coeff = 32'hbb306eeb;
                default: coeff = 32'h00000000;
            endcase
        end
    endfunction

    function [31:0] fir_result;
        input [31:0] newest;
        integer k;
        real acc;
        begin
            acc = fp32_to_real(newest) * fp32_to_real(coeff(0));
            for (k = 1; k < TAP_CNT; k = k + 1)
                acc = acc + fp32_to_real(samples[k-1]) * fp32_to_real(coeff(k));
            fir_result = real_to_fp32(acc);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            out_reg    <= 32'h00000000;
            valid_pipe <= 0;
            tail_pipe  <= 0;
            valid_in_d <= 1'b0;

            for (i = 0; i < TAP_CNT; i = i + 1)
                samples[i] <= 32'h00000000;
        end
    end

    always @(negedge clk) begin
        if (!rst) begin
            valid_pipe <= {valid_pipe[CENTER_DELAY-1:0], valid_in};
            tail_pipe  <= {tail_pipe[CENTER_DELAY-1:0], valid_in_d & ~valid_in};
            valid_in_d <= valid_in;

            out_reg <= fir_result(valid_in ? data_in : 32'h00000000);

            for (i = TAP_CNT-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];

            samples[0] <= valid_in ? data_in : 32'h00000000;
        end
    end

endmodule