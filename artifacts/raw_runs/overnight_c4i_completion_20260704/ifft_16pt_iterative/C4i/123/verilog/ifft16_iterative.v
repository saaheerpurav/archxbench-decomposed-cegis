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
    input mode,
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam LOGN   = 4;
    localparam OUT_W  = DATA_W + GAIN_W;
    localparam WORK_W = DATA_W + GAIN_W + LOGN;
    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [1:0] stage;
    reg [3:0] butterfly_count;
    reg done_r;

    reg signed [WORK_W-1:0] mem_real [0:N-1];
    reg signed [WORK_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];

    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;
    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [WORK_W-1:0] bf_p_real;
    wire signed [WORK_W-1:0] bf_p_imag;
    wire signed [WORK_W-1:0] bf_q_real;
    wire signed [WORK_W-1:0] bf_q_imag;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    assign done = done_r;

    fft16_index_gen u_index_gen (
        .stage(stage),
        .butterfly_count(butterfly_count[2:0]),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    ifft16_butterfly #(
        .WORK_W(WORK_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[p_idx]),
        .a_imag(mem_imag[p_idx]),
        .b_real(mem_real[q_idx]),
        .b_imag(mem_imag[q_idx]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .p_real(bf_p_real),
        .p_imag(bf_p_imag),
        .q_real(bf_q_real),
        .q_imag(bf_q_imag)
    );

    integer i;
    wire [3:0] load_rev_idx [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : LOAD_REV
            ifft16_bit_reverse u_bit_reverse (
                .idx(gi[3:0]),
                .rev_idx(load_rev_idx[gi])
            );
        end
    endgenerate

    wire signed [OUT_W-1:0] scaled_real [0:N-1];
    wire signed [OUT_W-1:0] scaled_imag [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : SCALE_OUT
            ifft16_output_scale #(
                .WORK_W(WORK_W),
                .OUT_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale (
                .in_real(mem_real[gi]),
                .in_imag(mem_imag[gi]),
                .out_real(scaled_real[gi]),
                .out_imag(scaled_imag[gi])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 2'd0;
            butterfly_count <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {WORK_W{1'b0}};
                mem_imag[i] <= {WORK_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_rev_idx[i]] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_rev_idx[i]] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        butterfly_count <= 4'd0;
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (butterfly_count == 4'd7) begin
                        butterfly_count <= 4'd0;
                        if (stage == 2'd3) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly_count <= butterfly_count + 4'd1;
                    end
                end

                S_DONE: begin
                    for (i = 0; i < N; i = i + 1) begin
                        out_real_r[i] <= scaled_real[i];
                        out_imag_r[i] <= scaled_imag[i];
                    end
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_rev_idx[i]] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_rev_idx[i]] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        butterfly_count <= 4'd0;
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule