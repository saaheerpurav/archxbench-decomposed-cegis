`timescale 1ns/1ps

module ifft16_iterative #(
    parameter N = 16,
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W = 4
) (
    input clk,
    input rst,
    input start,
    input mode, // 0: FFT, 1: IFFT
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam STAGES = 4;
    localparam TOTAL_BF = (N/2) * STAGES;

    localparam S_IDLE  = 2'd0;
    localparam S_RUN   = 2'd1;
    localparam S_SCALE = 2'd2;
    localparam S_DONE  = 2'd3;

    reg [1:0] state;
    reg [2:0] stage;
    reg [3:0] bf_idx;
    reg [3:0] scale_idx;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];

    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_a_real_out;
    wire signed [OUT_W-1:0] bf_a_imag_out;
    wire signed [OUT_W-1:0] bf_b_real_out;
    wire signed [OUT_W-1:0] bf_b_imag_out;

    wire signed [OUT_W-1:0] scaled_real;
    wire signed [OUT_W-1:0] scaled_imag;

    wire [3:0] br_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BR
            ifft16_bit_reverse_index u_bit_reverse_index (
                .idx_in (gi[3:0]),
                .idx_out(br_idx[gi])
            );

            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    assign done = (state == S_DONE);

    ifft16_stage_address u_stage_address (
        .stage (stage),
        .bf_idx(bf_idx[2:0]),
        .p_idx (p_idx),
        .q_idx (q_idx),
        .tw_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .mode  (mode),
        .cos_o (tw_cos),
        .sin_o (tw_sin)
    );

    ifft16_butterfly #(
        .DATA_W (OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real_in (mem_real[p_idx]),
        .a_imag_in (mem_imag[p_idx]),
        .b_real_in (mem_real[q_idx]),
        .b_imag_in (mem_imag[q_idx]),
        .tw_cos    (tw_cos),
        .tw_sin    (tw_sin),
        .a_real_out(bf_a_real_out),
        .a_imag_out(bf_a_imag_out),
        .b_real_out(bf_b_real_out),
        .b_imag_out(bf_b_imag_out)
    );

    ifft16_output_scale #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_output_scale (
        .real_in (mem_real[scale_idx]),
        .imag_in (mem_imag[scale_idx]),
        .mode    (mode),
        .real_out(scaled_real),
        .imag_out(scaled_imag)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd0;
            bf_idx <= 4'd0;
            scale_idx <= 4'd0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= {{GAIN_W{data_real_in[br_idx[i]][DATA_W-1]}}, data_real_in[br_idx[i]]};
                            mem_imag[i] <= {{GAIN_W{data_imag_in[br_idx[i]][DATA_W-1]}}, data_imag_in[br_idx[i]]};
                            out_real_r[i] <= {OUT_W{1'b0}};
                            out_imag_r[i] <= {OUT_W{1'b0}};
                        end
                        stage <= 3'd0;
                        bf_idx <= 4'd0;
                        scale_idx <= 4'd0;
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_a_real_out;
                    mem_imag[p_idx] <= bf_a_imag_out;
                    mem_real[q_idx] <= bf_b_real_out;
                    mem_imag[q_idx] <= bf_b_imag_out;

                    if (bf_idx == 4'd7) begin
                        bf_idx <= 4'd0;
                        if (stage == 3'd3) begin
                            scale_idx <= 4'd0;
                            state <= S_SCALE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        bf_idx <= bf_idx + 4'd1;
                    end
                end

                S_SCALE: begin
                    out_real_r[scale_idx] <= scaled_real;
                    out_imag_r[scale_idx] <= scaled_imag;

                    if (scale_idx == 4'd15) begin
                        state <= S_DONE;
                    end else begin
                        scale_idx <= scale_idx + 4'd1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= {{GAIN_W{data_real_in[br_idx[i]][DATA_W-1]}}, data_real_in[br_idx[i]]};
                            mem_imag[i] <= {{GAIN_W{data_imag_in[br_idx[i]][DATA_W-1]}}, data_imag_in[br_idx[i]]};
                            out_real_r[i] <= {OUT_W{1'b0}};
                            out_imag_r[i] <= {OUT_W{1'b0}};
                        end
                        stage <= 3'd0;
                        bf_idx <= 4'd0;
                        scale_idx <= 4'd0;
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule