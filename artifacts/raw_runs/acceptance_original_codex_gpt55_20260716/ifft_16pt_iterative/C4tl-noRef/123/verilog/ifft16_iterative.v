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
    localparam LOGN  = $clog2(N);

    localparam S_IDLE  = 2'd0;
    localparam S_RUN   = 2'd1;
    localparam S_SCALE = 2'd2;
    localparam S_DONE  = 2'd3;

    reg [1:0] state;
    reg [LOGN-1:0] stage;
    reg [LOGN-1:0] butterfly_count;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOGN-1:0] bitrev_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            ifft16_bitrev_index #(
                .N(N)
            ) u_bitrev_index (
                .index_in (gi[LOGN-1:0]),
                .index_out(bitrev_idx[gi])
            );
        end
    endgenerate

    wire [LOGN-1:0] addr_p;
    wire [LOGN-1:0] addr_q;
    wire [LOGN-1:0] tw_idx;

    ifft16_stage_addr #(
        .N(N)
    ) u_stage_addr (
        .stage          (stage),
        .butterfly_count(butterfly_count),
        .addr_p         (addr_p),
        .addr_q         (addr_q),
        .tw_idx         (tw_idx)
    );

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    ifft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_o (tw_cos),
        .sin_o (tw_sin)
    );

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode    (mode),
        .a_real  (mem_real[addr_p]),
        .a_imag  (mem_imag[addr_p]),
        .b_real  (mem_real[addr_q]),
        .b_imag  (mem_imag[addr_q]),
        .tw_cos  (tw_cos),
        .tw_sin  (tw_sin),
        .y0_real (bf_p_real),
        .y0_imag (bf_p_imag),
        .y1_real (bf_q_real),
        .y1_imag (bf_q_imag)
    );

    wire signed [OUT_W-1:0] scaled_real [0:N-1];
    wire signed [OUT_W-1:0] scaled_imag [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_SCALE
            ifft16_output_scale #(
                .DATA_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_output_scale (
                .mode    (mode),
                .in_real (mem_real[gi]),
                .in_imag (mem_imag[gi]),
                .out_real(scaled_real[gi]),
                .out_imag(scaled_imag[gi])
            );

            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    assign done = done_r;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= {LOGN{1'b0}};
            butterfly_count <= {LOGN{1'b0}};
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= {LOGN{1'b0}};
                    butterfly_count <= {LOGN{1'b0}};
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[addr_p] <= bf_p_real;
                    mem_imag[addr_p] <= bf_p_imag;
                    mem_real[addr_q] <= bf_q_real;
                    mem_imag[addr_q] <= bf_q_imag;

                    if (butterfly_count == (N/2 - 1)) begin
                        butterfly_count <= {LOGN{1'b0}};
                        if (stage == (LOGN - 1)) begin
                            state <= S_SCALE;
                        end else begin
                            stage <= stage + 1'b1;
                        end
                    end else begin
                        butterfly_count <= butterfly_count + 1'b1;
                    end
                end

                S_SCALE: begin
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[i] <= scaled_real[i];
                        mem_imag[i] <= scaled_imag[i];
                    end
                    done_r <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        stage <= {LOGN{1'b0}};
                        butterfly_count <= {LOGN{1'b0}};
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