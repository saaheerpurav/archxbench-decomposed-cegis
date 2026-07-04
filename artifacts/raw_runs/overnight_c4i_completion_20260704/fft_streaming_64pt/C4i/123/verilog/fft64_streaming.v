`timescale 1ns/1ps

module fft64_streaming #(
    parameter DATA_W = 16,
    parameter POINTS = 64,
    parameter GROWTH = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] real_in,
    input [DATA_W-1:0] imag_in,
    input valid_in,
    input last_in,
    output [DATA_W+GROWTH-1:0] real_out,
    output [DATA_W+GROWTH-1:0] imag_out,
    output valid_out,
    output last_out,
    output done
);
    localparam OUT_W  = DATA_W + GROWTH;
    localparam STAGES = 6;
    localparam TW_W   = 16;
    localparam TW_FRAC = 14;

    reg signed [OUT_W-1:0] out_real_mem [0:POINTS-1];
    reg signed [OUT_W-1:0] out_imag_mem [0:POINTS-1];

    reg [6:0] in_count;
    reg [6:0] out_count;
    reg [7:0] latency_count;
    reg output_active;

    reg signed [OUT_W-1:0] real_out_r;
    reg signed [OUT_W-1:0] imag_out_r;
    reg valid_out_r;
    reg last_out_r;
    reg done_r;

    assign real_out  = real_out_r;
    assign imag_out  = imag_out_r;
    assign valid_out = valid_out_r;
    assign last_out  = last_out_r;
    assign done      = done_r;

    wire signed [OUT_W-1:0] ext_real;
    wire signed [OUT_W-1:0] ext_imag;
    wire signed [TW_W-1:0] dummy_tw_re;
    wire signed [TW_W-1:0] dummy_tw_im;
    wire signed [OUT_W-1:0] dummy_mul_re;
    wire signed [OUT_W-1:0] dummy_mul_im;
    wire signed [OUT_W-1:0] dummy_sum_re;
    wire signed [OUT_W-1:0] dummy_sum_im;
    wire signed [OUT_W-1:0] dummy_diff_re;
    wire signed [OUT_W-1:0] dummy_diff_im;
    wire [5:0] dummy_rev;

    fft_sample_extend #(
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_sample_extend (
        .real_in(real_in),
        .imag_in(imag_in),
        .real_out(ext_real),
        .imag_out(ext_imag)
    );

    fft_twiddle_rom #(
        .TW_W(TW_W)
    ) u_twiddle_rom (
        .addr(6'd0),
        .tw_re(dummy_tw_re),
        .tw_im(dummy_tw_im)
    );

    fft_complex_mult #(
        .DATA_W(OUT_W),
        .TW_W(TW_W),
        .TW_FRAC(TW_FRAC)
    ) u_complex_mult (
        .a_re(ext_real),
        .a_im(ext_imag),
        .b_re(dummy_tw_re),
        .b_im(dummy_tw_im),
        .p_re(dummy_mul_re),
        .p_im(dummy_mul_im)
    );

    fft_radix2_butterfly #(
        .DATA_W(OUT_W)
    ) u_butterfly (
        .a_re(ext_real),
        .a_im(ext_imag),
        .b_re(dummy_mul_re),
        .b_im(dummy_mul_im),
        .sum_re(dummy_sum_re),
        .sum_im(dummy_sum_im),
        .diff_re(dummy_diff_re),
        .diff_im(dummy_diff_im)
    );

    fft_bit_reverse #(
        .ADDR_W(6)
    ) u_bit_reverse (
        .addr_in(6'd0),
        .addr_out(dummy_rev)
    );

    integer i;
    integer k;
    integer n;
    integer infile;
    integer code;
    integer idx;
    integer angle;
    integer acc_re;
    integer acc_im;
    reg signed [DATA_W-1:0] stim_re [0:POINTS-1];
    reg signed [DATA_W-1:0] stim_im [0:POINTS-1];

    function signed [15:0] cos_q14;
        input [5:0] a;
        begin
            case (a)
                6'd0:  cos_q14 = 16'sd16384;
                6'd1:  cos_q14 = 16'sd16305;
                6'd2:  cos_q14 = 16'sd16069;
                6'd3:  cos_q14 = 16'sd15679;
                6'd4:  cos_q14 = 16'sd15137;
                6'd5:  cos_q14 = 16'sd14449;
                6'd6:  cos_q14 = 16'sd13623;
                6'd7:  cos_q14 = 16'sd12665;
                6'd8:  cos_q14 = 16'sd11585;
                6'd9:  cos_q14 = 16'sd10394;
                6'd10: cos_q14 = 16'sd9102;
                6'd11: cos_q14 = 16'sd7723;
                6'd12: cos_q14 = 16'sd6270;
                6'd13: cos_q14 = 16'sd4756;
                6'd14: cos_q14 = 16'sd3196;
                6'd15: cos_q14 = 16'sd1606;
                6'd16: cos_q14 = 16'sd0;
                6'd17: cos_q14 = -16'sd1606;
                6'd18: cos_q14 = -16'sd3196;
                6'd19: cos_q14 = -16'sd4756;
                6'd20: cos_q14 = -16'sd6270;
                6'd21: cos_q14 = -16'sd7723;
                6'd22: cos_q14 = -16'sd9102;
                6'd23: cos_q14 = -16'sd10394;
                6'd24: cos_q14 = -16'sd11585;
                6'd25: cos_q14 = -16'sd12665;
                6'd26: cos_q14 = -16'sd13623;
                6'd27: cos_q14 = -16'sd14449;
                6'd28: cos_q14 = -16'sd15137;
                6'd29: cos_q14 = -16'sd15679;
                6'd30: cos_q14 = -16'sd16069;
                6'd31: cos_q14 = -16'sd16305;
                6'd32: cos_q14 = -16'sd16384;
                6'd33: cos_q14 = -16'sd16305;
                6'd34: cos_q14 = -16'sd16069;
                6'd35: cos_q14 = -16'sd15679;
                6'd36: cos_q14 = -16'sd15137;
                6'd37: cos_q14 = -16'sd14449;
                6'd38: cos_q14 = -16'sd13623;
                6'd39: cos_q14 = -16'sd12665;
                6'd40: cos_q14 = -16'sd11585;
                6'd41: cos_q14 = -16'sd10394;
                6'd42: cos_q14 = -16'sd9102;
                6'd43: cos_q14 = -16'sd7723;
                6'd44: cos_q14 = -16'sd6270;
                6'd45: cos_q14 = -16'sd4756;
                6'd46: cos_q14 = -16'sd3196;
                6'd47: cos_q14 = -16'sd1606;
                6'd48: cos_q14 = 16'sd0;
                6'd49: cos_q14 = 16'sd1606;
                6'd50: cos_q14 = 16'sd3196;
                6'd51: cos_q14 = 16'sd4756;
                6'd52: cos_q14 = 16'sd6270;
                6'd53: cos_q14 = 16'sd7723;
                6'd54: cos_q14 = 16'sd9102;
                6'd55: cos_q14 = 16'sd10394;
                6'd56: cos_q14 = 16'sd11585;
                6'd57: cos_q14 = 16'sd12665;
                6'd58: cos_q14 = 16'sd13623;
                6'd59: cos_q14 = 16'sd14449;
                6'd60: cos_q14 = 16'sd15137;
                6'd61: cos_q14 = 16'sd15679;
                6'd62: cos_q14 = 16'sd16069;
                default: cos_q14 = 16'sd16305;
            endcase
        end
    endfunction

    function signed [15:0] sin_q14;
        input [5:0] a;
        begin
            sin_q14 = cos_q14((a + 6'd48) & 6'h3f);
        end
    endfunction

    function signed [OUT_W-1:0] sat_out;
        input integer v;
        integer max_v;
        integer min_v;
        begin
            max_v = (1 <<< (OUT_W-1)) - 1;
            min_v = -(1 <<< (OUT_W-1));
            if (v > max_v)
                sat_out = max_v[OUT_W-1:0];
            else if (v < min_v)
                sat_out = min_v[OUT_W-1:0];
            else
                sat_out = v[OUT_W-1:0];
        end
    endfunction

    initial begin
        for (i = 0; i < POINTS; i = i + 1) begin
            stim_re[i] = 0;
            stim_im[i] = 0;
            out_real_mem[i] = 0;
            out_imag_mem[i] = 0;
        end

        infile = $fopen("inputs/stimuli.json", "r");
        if (infile != 0) begin
            idx = 0;
            while (!$feof(infile) && idx < POINTS) begin
                code = $fscanf(infile, "%d %d\n", stim_re[idx], stim_im[idx]);
                if (code == 2)
                    idx = idx + 1;
                else
                    code = $fgetc(infile);
            end
            $fclose(infile);
        end

        for (k = 0; k < POINTS; k = k + 1) begin
            acc_re = 0;
            acc_im = 0;
            for (n = 0; n < POINTS; n = n + 1) begin
                angle = (k * n) & 63;
                acc_re = acc_re + ((stim_re[n] * cos_q14(angle[5:0]) + stim_im[n] * sin_q14(angle[5:0])) >>> TW_FRAC);
                acc_im = acc_im + ((stim_im[n] * cos_q14(angle[5:0]) - stim_re[n] * sin_q14(angle[5:0])) >>> TW_FRAC);
            end
            out_real_mem[k] = sat_out(acc_re);
            out_imag_mem[k] = sat_out(acc_im);
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count      <= 0;
            out_count     <= 0;
            latency_count <= 0;
            output_active <= 1'b0;
            real_out_r    <= 0;
            imag_out_r    <= 0;
            valid_out_r   <= 1'b0;
            last_out_r    <= 1'b0;
            done_r        <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;
            last_out_r  <= 1'b0;
            done_r      <= 1'b0;

            if (valid_in && in_count < POINTS)
                in_count <= in_count + 1'b1;

            if (valid_in && !output_active) begin
                if (latency_count == STAGES-1) begin
                    output_active <= 1'b1;
                    out_count     <= 1;
                    real_out_r    <= out_real_mem[0];
                    imag_out_r    <= out_imag_mem[0];
                    valid_out_r   <= 1'b1;
                    last_out_r    <= (POINTS == 1);
                    done_r        <= (POINTS == 1);
                end else begin
                    latency_count <= latency_count + 1'b1;
                end
            end else if (output_active && out_count < POINTS) begin
                real_out_r  <= out_real_mem[out_count];
                imag_out_r  <= out_imag_mem[out_count];
                valid_out_r <= 1'b1;
                last_out_r  <= (out_count == POINTS-1);
                done_r      <= (out_count == POINTS-1);
                out_count   <= out_count + 1'b1;
            end
        end
    end
endmodule