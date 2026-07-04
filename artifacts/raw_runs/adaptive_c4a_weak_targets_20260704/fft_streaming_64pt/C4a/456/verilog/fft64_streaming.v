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
    localparam STAGES = $clog2(POINTS);

    wire signed [OUT_W-1:0] in_real_ext;
    wire signed [OUT_W-1:0] in_imag_ext;

    fft_sign_extend #(
        .IN_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_input_extend (
        .in_real(real_in),
        .in_imag(imag_in),
        .out_real(in_real_ext),
        .out_imag(in_imag_ext)
    );

    reg signed [OUT_W-1:0] pipe_real [0:STAGES];
    reg signed [OUT_W-1:0] pipe_imag [0:STAGES];
    reg                    pipe_valid[0:STAGES];
    reg                    pipe_last [0:STAGES];

    reg [$clog2(POINTS)-1:0] sample_count;

    wire signed [OUT_W-1:0] stage_real [0:STAGES-1];
    wire signed [OUT_W-1:0] stage_imag [0:STAGES-1];

    genvar gi;
    generate
        for (gi = 0; gi < STAGES; gi = gi + 1) begin : g_fft_stages
            wire signed [OUT_W-1:0] tw_real;
            wire signed [OUT_W-1:0] tw_imag;
            wire signed [OUT_W-1:0] bf_sum_real;
            wire signed [OUT_W-1:0] bf_sum_imag;
            wire signed [OUT_W-1:0] bf_diff_real;
            wire signed [OUT_W-1:0] bf_diff_imag;
            wire signed [OUT_W-1:0] mult_real;
            wire signed [OUT_W-1:0] mult_imag;

            fft_twiddle_rom #(
                .DATA_W(OUT_W),
                .POINTS(POINTS)
            ) u_twiddle_rom (
                .index(sample_count),
                .tw_real(tw_real),
                .tw_imag(tw_imag)
            );

            fft_radix2_butterfly #(
                .DATA_W(OUT_W)
            ) u_butterfly (
                .a_real(pipe_real[gi]),
                .a_imag(pipe_imag[gi]),
                .b_real({OUT_W{1'b0}}),
                .b_imag({OUT_W{1'b0}}),
                .sum_real(bf_sum_real),
                .sum_imag(bf_sum_imag),
                .diff_real(bf_diff_real),
                .diff_imag(bf_diff_imag)
            );

            fft_complex_mult #(
                .DATA_W(OUT_W)
            ) u_complex_mult (
                .a_real(bf_sum_real),
                .a_imag(bf_sum_imag),
                .b_real(tw_real),
                .b_imag(tw_imag),
                .p_real(mult_real),
                .p_imag(mult_imag)
            );

            fft_stage_select #(
                .DATA_W(OUT_W),
                .STAGE(gi)
            ) u_stage_select (
                .sample_index(sample_count),
                .sum_real(bf_sum_real),
                .sum_imag(bf_sum_imag),
                .diff_real(mult_real),
                .diff_imag(mult_imag),
                .out_real(stage_real[gi]),
                .out_imag(stage_imag[gi])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            sample_count <= {($clog2(POINTS)){1'b0}};
            for (i = 0; i <= STAGES; i = i + 1) begin
                pipe_real[i]  <= {OUT_W{1'b0}};
                pipe_imag[i]  <= {OUT_W{1'b0}};
                pipe_valid[i] <= 1'b0;
                pipe_last[i]  <= 1'b0;
            end
        end else begin
            if (valid_in) begin
                if (last_in)
                    sample_count <= {($clog2(POINTS)){1'b0}};
                else
                    sample_count <= sample_count + 1'b1;
            end

            pipe_real[0]  <= in_real_ext;
            pipe_imag[0]  <= in_imag_ext;
            pipe_valid[0] <= valid_in;
            pipe_last[0]  <= last_in;

            for (i = 0; i < STAGES; i = i + 1) begin
                pipe_real[i+1]  <= stage_real[i];
                pipe_imag[i+1]  <= stage_imag[i];
                pipe_valid[i+1] <= pipe_valid[i];
                pipe_last[i+1]  <= pipe_last[i];
            end
        end
    end

    assign real_out  = pipe_real[STAGES];
    assign imag_out  = pipe_imag[STAGES];
    assign valid_out = pipe_valid[STAGES];
    assign last_out  = pipe_last[STAGES];
    assign done      = valid_out & last_out;

endmodule