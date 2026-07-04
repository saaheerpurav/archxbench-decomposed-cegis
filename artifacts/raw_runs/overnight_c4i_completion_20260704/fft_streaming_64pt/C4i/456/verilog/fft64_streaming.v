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

    wire signed [OUT_W-1:0] in_real_ext;
    wire signed [OUT_W-1:0] in_imag_ext;

    wire signed [OUT_W-1:0] stage_real_comb [0:STAGES-1];
    wire signed [OUT_W-1:0] stage_imag_comb [0:STAGES-1];
    wire signed [OUT_W-1:0] tw_real [0:STAGES-1];
    wire signed [OUT_W-1:0] tw_imag [0:STAGES-1];

    reg signed [OUT_W-1:0] real_pipe [0:STAGES-1];
    reg signed [OUT_W-1:0] imag_pipe [0:STAGES-1];
    reg [STAGES-1:0] valid_pipe;
    reg [STAGES-1:0] last_pipe;
    reg [STAGES-1:0] sample_count;

    integer i;

    fft_sign_extend #(
        .IN_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_input_extend (
        .real_in(real_in),
        .imag_in(imag_in),
        .real_out(in_real_ext),
        .imag_out(in_imag_ext)
    );

    genvar g;
    generate
        for (g = 0; g < STAGES; g = g + 1) begin : gen_fft_stages
            fft_twiddle_rom #(
                .DATA_W(OUT_W),
                .POINTS(POINTS),
                .STAGE(g)
            ) u_twiddle_rom (
                .index(sample_count),
                .tw_real(tw_real[g]),
                .tw_imag(tw_imag[g])
            );

            fft_radix2_stage #(
                .DATA_W(OUT_W),
                .STAGE(g)
            ) u_radix2_stage (
                .real_in((g == 0) ? in_real_ext : real_pipe[g-1]),
                .imag_in((g == 0) ? in_imag_ext : imag_pipe[g-1]),
                .tw_real(tw_real[g]),
                .tw_imag(tw_imag[g]),
                .sample_index(sample_count),
                .real_out(stage_real_comb[g]),
                .imag_out(stage_imag_comb[g])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            sample_count <= {STAGES{1'b0}};
            valid_pipe   <= {STAGES{1'b0}};
            last_pipe    <= {STAGES{1'b0}};
            for (i = 0; i < STAGES; i = i + 1) begin
                real_pipe[i] <= {OUT_W{1'b0}};
                imag_pipe[i] <= {OUT_W{1'b0}};
            end
        end else begin
            valid_pipe <= {valid_pipe[STAGES-2:0], valid_in};
            last_pipe  <= {last_pipe[STAGES-2:0], last_in};

            if (valid_in) begin
                if (last_in)
                    sample_count <= {STAGES{1'b0}};
                else
                    sample_count <= sample_count + {{(STAGES-1){1'b0}}, 1'b1};
            end

            real_pipe[0] <= stage_real_comb[0];
            imag_pipe[0] <= stage_imag_comb[0];

            for (i = 1; i < STAGES; i = i + 1) begin
                real_pipe[i] <= stage_real_comb[i];
                imag_pipe[i] <= stage_imag_comb[i];
            end
        end
    end

    assign real_out  = real_pipe[STAGES-1];
    assign imag_out  = imag_pipe[STAGES-1];
    assign valid_out = valid_pipe[STAGES-1];
    assign last_out  = last_pipe[STAGES-1];
    assign done      = valid_pipe[STAGES-1] & last_pipe[STAGES-1];

endmodule