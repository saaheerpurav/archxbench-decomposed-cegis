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

    fft64_sign_extend #(
        .IN_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_input_extend (
        .real_in(real_in),
        .imag_in(imag_in),
        .real_out(in_real_ext),
        .imag_out(in_imag_ext)
    );

    reg signed [OUT_W-1:0] pipe_real [0:STAGES];
    reg signed [OUT_W-1:0] pipe_imag [0:STAGES];
    reg signed [OUT_W-1:0] delay_real [0:STAGES-1];
    reg signed [OUT_W-1:0] delay_imag [0:STAGES-1];
    reg [STAGES-1:0] valid_pipe;
    reg [STAGES-1:0] last_pipe;
    reg [STAGES-1:0] sample_count;

    wire signed [OUT_W-1:0] stage_real [0:STAGES-1];
    wire signed [OUT_W-1:0] stage_imag [0:STAGES-1];

    genvar gi;
    generate
        for (gi = 0; gi < STAGES; gi = gi + 1) begin : g_fft_stages
            wire signed [OUT_W-1:0] sum_real;
            wire signed [OUT_W-1:0] sum_imag;
            wire signed [OUT_W-1:0] diff_real;
            wire signed [OUT_W-1:0] diff_imag;
            wire signed [15:0] tw_real;
            wire signed [15:0] tw_imag;
            wire signed [OUT_W-1:0] rot_real;
            wire signed [OUT_W-1:0] rot_imag;

            fft64_radix2_butterfly #(
                .DATA_W(OUT_W)
            ) u_butterfly (
                .a_real(pipe_real[gi]),
                .a_imag(pipe_imag[gi]),
                .b_real(delay_real[gi]),
                .b_imag(delay_imag[gi]),
                .sum_real(sum_real),
                .sum_imag(sum_imag),
                .diff_real(diff_real),
                .diff_imag(diff_imag)
            );

            fft64_twiddle_rom #(
                .POINTS(POINTS)
            ) u_twiddle (
                .addr(sample_count),
                .stage(gi[STAGES-1:0]),
                .tw_real(tw_real),
                .tw_imag(tw_imag)
            );

            fft64_complex_mult #(
                .DATA_W(OUT_W),
                .TW_W(16)
            ) u_complex_mult (
                .a_real(diff_real),
                .a_imag(diff_imag),
                .b_real(tw_real),
                .b_imag(tw_imag),
                .p_real(rot_real),
                .p_imag(rot_imag)
            );

            fft64_stage_select #(
                .DATA_W(OUT_W)
            ) u_stage_select (
                .select_upper(sample_count[gi]),
                .sum_real(sum_real),
                .sum_imag(sum_imag),
                .diff_real(rot_real),
                .diff_imag(rot_imag),
                .out_real(stage_real[gi]),
                .out_imag(stage_imag[gi])
            );
        end
    endgenerate

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            pipe_real[0] <= {OUT_W{1'b0}};
            pipe_imag[0] <= {OUT_W{1'b0}};
            for (i = 0; i < STAGES; i = i + 1) begin
                pipe_real[i+1] <= {OUT_W{1'b0}};
                pipe_imag[i+1] <= {OUT_W{1'b0}};
                delay_real[i] <= {OUT_W{1'b0}};
                delay_imag[i] <= {OUT_W{1'b0}};
            end
            valid_pipe <= {STAGES{1'b0}};
            last_pipe <= {STAGES{1'b0}};
            sample_count <= {STAGES{1'b0}};
        end else begin
            if (valid_in) begin
                sample_count <= sample_count + {{(STAGES-1){1'b0}}, 1'b1};
            end

            pipe_real[0] <= in_real_ext;
            pipe_imag[0] <= in_imag_ext;

            for (i = 0; i < STAGES; i = i + 1) begin
                delay_real[i] <= pipe_real[i];
                delay_imag[i] <= pipe_imag[i];
                pipe_real[i+1] <= stage_real[i];
                pipe_imag[i+1] <= stage_imag[i];
            end

            valid_pipe <= {valid_pipe[STAGES-2:0], valid_in};
            last_pipe <= {last_pipe[STAGES-2:0], last_in};
        end
    end

    assign real_out = pipe_real[STAGES];
    assign imag_out = pipe_imag[STAGES];
    assign valid_out = valid_pipe[STAGES-1];
    assign last_out = last_pipe[STAGES-1];
    assign done = valid_out & last_out;

endmodule