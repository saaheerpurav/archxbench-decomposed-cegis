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

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam STAGES = 4;
    localparam IDLE   = 2'd0;
    localparam RUN    = 2'd1;
    localparam DONE_S = 2'd2;

    reg [1:0] state;
    reg done_r;

    reg [2:0] stage;
    reg [3:0] group_base;
    reg [3:0] j_count;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] load_rev_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            ifft16_bit_reverse_index #(.INDEX(gi)) u_bitrev (
                .reversed(load_rev_idx[gi])
            );
        end
    endgenerate

    wire [3:0] m_val       = 4'd1 << (stage + 1'b1);
    wire [3:0] half_m      = 4'd1 << stage;
    wire [3:0] tw_stride   = 4'd16 >> (stage + 1'b1);
    wire [3:0] tw_idx      = j_count * tw_stride;
    wire [3:0] p_idx       = group_base + j_count;
    wire [3:0] q_idx       = group_base + j_count + half_m;

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
        .COEFF_W(COEFF_W),
        .OUT_W(OUT_W)
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

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_SCALE
            ifft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_real (
                .din(mem_real[gi]),
                .dout(data_real_out[gi])
            );

            ifft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_scale_imag (
                .din(mem_imag[gi]),
                .dout(data_imag_out[gi])
            );
        end
    endgenerate

    assign done = done_r;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            done_r     <= 1'b0;
            stage      <= 3'd0;
            group_base <= 4'd0;
            j_count    <= 4'd0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_rev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_rev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage      <= 3'd0;
                        group_base <= 4'd0;
                        j_count    <= 4'd0;
                        state      <= RUN;
                    end
                end

                RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (j_count == half_m - 1'b1) begin
                        j_count <= 4'd0;
                        if (group_base + m_val >= N[3:0]) begin
                            group_base <= 4'd0;
                            if (stage == STAGES - 1) begin
                                state  <= DONE_S;
                                done_r <= 1'b1;
                            end else begin
                                stage <= stage + 1'b1;
                            end
                        end else begin
                            group_base <= group_base + m_val;
                        end
                    end else begin
                        j_count <= j_count + 1'b1;
                    end
                end

                DONE_S: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_rev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_rev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage      <= 3'd0;
                        group_base <= 4'd0;
                        j_count    <= 4'd0;
                        state      <= RUN;
                    end
                end

                default: begin
                    state  <= IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

    wire unused_mode = mode;

endmodule