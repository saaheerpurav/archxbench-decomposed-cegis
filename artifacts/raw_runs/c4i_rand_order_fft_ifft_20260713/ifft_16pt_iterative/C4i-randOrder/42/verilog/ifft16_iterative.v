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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOG_N = 4;
    localparam NUM_BF = N / 2;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [2:0] stage;
    reg [3:0] bf_count;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];

    wire [3:0] bitrev_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            ifft16_bit_reverse u_bit_reverse (
                .idx_in(gi[3:0]),
                .idx_out(bitrev_idx[gi])
            );
        end
    endgenerate

    wire [3:0] m_size;
    wire [3:0] half_size;
    wire [3:0] tw_step;
    wire [3:0] group_idx;
    wire [3:0] j_idx;
    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    assign m_size    = 4'd2 << stage;
    assign half_size = 4'd1 << stage;
    assign tw_step   = 4'd16 >> (stage + 1'b1);
    assign group_idx = bf_count / half_size;
    assign j_idx     = bf_count % half_size;
    assign p_idx     = (group_idx * m_size) + j_idx;
    assign q_idx     = p_idx + half_size;
    assign tw_idx    = j_idx * tw_step;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    ifft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[p_idx]),
        .a_imag(mem_imag[p_idx]),
        .b_real(mem_real[q_idx]),
        .b_imag(mem_imag[q_idx]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    wire signed [OUT_W-1:0] scaled_real [0:N-1];
    wire signed [OUT_W-1:0] scaled_imag [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_SCALE
            ifft16_output_scale #(
                .DATA_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_output_scale (
                .in_real(mem_real[gi]),
                .in_imag(mem_imag[gi]),
                .out_real(scaled_real[gi]),
                .out_imag(scaled_imag[gi])
            );
        end
    endgenerate

    assign done = done_r;

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUT_ASSIGN
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd0;
            bf_count <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= 3'd0;
                    bf_count <= 4'd0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (bf_count == NUM_BF-1) begin
                        bf_count <= 4'd0;
                        if (stage == LOG_N-1) begin
                            for (i = 0; i < N; i = i + 1) begin
                                if (i == p_idx) begin
                                    out_real_r[i] <= bf_p_real >>> GAIN_W;
                                    out_imag_r[i] <= bf_p_imag >>> GAIN_W;
                                end else if (i == q_idx) begin
                                    out_real_r[i] <= bf_q_real >>> GAIN_W;
                                    out_imag_r[i] <= bf_q_imag >>> GAIN_W;
                                end else begin
                                    out_real_r[i] <= scaled_real[i];
                                    out_imag_r[i] <= scaled_imag[i];
                                end
                            end
                            done_r <= 1'b1;
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        bf_count <= bf_count + 4'd1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        stage <= 3'd0;
                        bf_count <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
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