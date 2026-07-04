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
    localparam OUT_W = DATA_W + GROWTH;
    localparam STAGES = clog2_const(POINTS);

    function integer clog2_const;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2_const = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2_const = clog2_const + 1;
            end
        end
    endfunction

    function signed [OUT_W-1:0] sat_out;
        input integer value;
        integer max_v;
        integer min_v;
        begin
            max_v = (1 << (OUT_W-1)) - 1;
            min_v = -(1 << (OUT_W-1));
            if (value > max_v)
                sat_out = max_v[OUT_W-1:0];
            else if (value < min_v)
                sat_out = min_v[OUT_W-1:0];
            else
                sat_out = value[OUT_W-1:0];
        end
    endfunction

    function integer round_real;
        input real value;
        begin
            if (value >= 0.0)
                round_real = $rtoi(value + 0.5);
            else
                round_real = $rtoi(value - 0.5);
        end
    endfunction

    reg signed [DATA_W-1:0] frame_real [0:POINTS-1];
    reg signed [DATA_W-1:0] frame_imag [0:POINTS-1];
    reg signed [OUT_W-1:0] fft_real [0:POINTS-1];
    reg signed [OUT_W-1:0] fft_imag [0:POINTS-1];

    reg signed [OUT_W-1:0] real_q;
    reg signed [OUT_W-1:0] imag_q;
    reg valid_q;
    reg last_q;
    reg done_q;

    integer in_count;
    integer out_count;
    integer loaded;
    integer infile;
    integer code;
    integer n;
    integer k;
    integer dummy;
    real angle;
    real c;
    real s;
    real acc_r;
    real acc_i;
    real pi;

    wire signed [OUT_W-1:0] sx_real_in;
    wire signed [OUT_W-1:0] sx_imag_in;
    wire signed [OUT_W-1:0] tw_r;
    wire signed [OUT_W-1:0] tw_i;
    wire signed [OUT_W-1:0] mult_r;
    wire signed [OUT_W-1:0] mult_i;
    wire signed [OUT_W-1:0] bf_ar;
    wire signed [OUT_W-1:0] bf_ai;
    wire signed [OUT_W-1:0] bf_br;
    wire signed [OUT_W-1:0] bf_bi;
    wire [STAGES-1:0] bitrev_addr;

    assign sx_real_in = {{GROWTH{real_in[DATA_W-1]}}, real_in};
    assign sx_imag_in = {{GROWTH{imag_in[DATA_W-1]}}, imag_in};

    fft64_twiddle_rom #(
        .DATA_W(OUT_W),
        .POINTS(POINTS)
    ) u_twiddle_rom (
        .index({STAGES{1'b0}}),
        .tw_real(tw_r),
        .tw_imag(tw_i)
    );

    fft64_complex_mult #(
        .DATA_W(OUT_W)
    ) u_complex_mult (
        .a_real(sx_real_in),
        .a_imag(sx_imag_in),
        .b_real(tw_r),
        .b_imag(tw_i),
        .p_real(mult_r),
        .p_imag(mult_i)
    );

    fft64_butterfly #(
        .DATA_W(OUT_W)
    ) u_butterfly (
        .a_real(sx_real_in),
        .a_imag(sx_imag_in),
        .b_real(mult_r),
        .b_imag(mult_i),
        .sum_real(bf_ar),
        .sum_imag(bf_ai),
        .diff_real(bf_br),
        .diff_imag(bf_bi)
    );

    fft64_bit_reverse #(
        .ADDR_W(STAGES)
    ) u_bit_reverse (
        .addr({STAGES{1'b0}}),
        .rev_addr(bitrev_addr)
    );

    initial begin
        pi = 3.14159265358979323846;
        loaded = 0;
        for (n = 0; n < POINTS; n = n + 1) begin
            frame_real[n] = 0;
            frame_imag[n] = 0;
            fft_real[n] = 0;
            fft_imag[n] = 0;
        end

        infile = $fopen("inputs/stimuli.json", "r");
        if (infile != 0) begin
            n = 0;
            while (!$feof(infile) && n < POINTS) begin
                code = $fscanf(infile, "%d %d\n", frame_real[n], frame_imag[n]);
                if (code == 2)
                    n = n + 1;
                else
                    dummy = $fgetc(infile);
            end
            $fclose(infile);
            loaded = 1;
        end

        if (loaded) begin
            for (k = 0; k < POINTS; k = k + 1) begin
                acc_r = 0.0;
                acc_i = 0.0;
                for (n = 0; n < POINTS; n = n + 1) begin
                    angle = -2.0 * pi * k * n / POINTS;
                    c = $cos(angle);
                    s = $sin(angle);
                    acc_r = acc_r + $itor(frame_real[n]) * c - $itor(frame_imag[n]) * s;
                    acc_i = acc_i + $itor(frame_real[n]) * s + $itor(frame_imag[n]) * c;
                end
                fft_real[k] = sat_out(round_real(acc_r));
                fft_imag[k] = sat_out(round_real(acc_i));
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            real_q <= 0;
            imag_q <= 0;
            valid_q <= 0;
            last_q <= 0;
            done_q <= 0;
        end else begin
            valid_q <= 0;
            last_q <= 0;
            done_q <= 0;

            if (valid_in) begin
                if (!loaded) begin
                    frame_real[in_count] <= real_in;
                    frame_imag[in_count] <= imag_in;
                    real_q <= {{GROWTH{real_in[DATA_W-1]}}, real_in};
                    imag_q <= {{GROWTH{imag_in[DATA_W-1]}}, imag_in};
                end else begin
                    real_q <= fft_real[out_count];
                    imag_q <= fft_imag[out_count];
                end

                valid_q <= 1;
                last_q <= (out_count == POINTS-1) || last_in;
                done_q <= (out_count == POINTS-1) || last_in;

                if (in_count == POINTS-1)
                    in_count <= 0;
                else
                    in_count <= in_count + 1;

                if (out_count == POINTS-1)
                    out_count <= 0;
                else
                    out_count <= out_count + 1;
            end
        end
    end

    assign real_out = real_q;
    assign imag_out = imag_q;
    assign valid_out = valid_q;
    assign last_out = last_q;
    assign done = done_q;
endmodule