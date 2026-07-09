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
    localparam LOGN  = 4; // log2(16)

    // Memory storing intermediate values, width = OUT_W to allow growth
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // Bit reversed index wires
    wire [3:0] rev_idx [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : REV_GEN
            bitrev4 u_bitrev (
                .idx_in(gi[3:0]),
                .idx_out(rev_idx[gi])
            );
        end
    endgenerate

    // FSM states
    localparam S_IDLE       = 3'd0;
    localparam S_LOAD       = 3'd1;
    localparam S_BUTTERFLY  = 3'd2;
    localparam S_NEXT_PAIR  = 3'd3;
    localparam S_SCALE      = 3'd4;
    localparam S_DONE       = 3'd5;

    reg [2:0] state;

    reg [3:0] stage;       // 0..LOGN-1
    reg [3:0] pair_idx;    // index within the group of butterflies processed this stage (0..N/2-1)

    reg done_reg;
    assign done = done_reg;

    // Index generation for current stage/pair
    wire [3:0] p_idx, q_idx;
    wire [3:0] tw_idx;

    fft_index_gen #(
        .N(N),
        .LOGN(LOGN)
    ) u_index_gen (
        .stage(stage),
        .pair_idx(pair_idx),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    // Twiddle ROM
    wire signed [COEFF_W-1:0] cos_val, sin_val;
    twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle (
        .tw_idx(tw_idx),
        .mode(mode),
        .cos_val(cos_val),
        .sin_val(sin_val)
    );

    // Butterfly unit (combinational)
    wire signed [OUT_W-1:0] xp_re_in, xp_im_in, xq_re_in, xq_im_in;
    assign xp_re_in = mem_real[p_idx];
    assign xp_im_in = mem_imag[p_idx];
    assign xq_re_in = mem_real[q_idx];
    assign xq_im_in = mem_imag[q_idx];

    wire signed [OUT_W-1:0] xp_re_out, xp_im_out, xq_re_out, xq_im_out;

    butterfly_unit #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .xp_re(xp_re_in),
        .xp_im(xp_im_in),
        .xq_re(xq_re_in),
        .xq_im(xq_im_in),
        .cos_val(cos_val),
        .sin_val(sin_val),
        .yp_re(xp_re_out),
        .yp_im(xp_im_out),
        .yq_re(xq_re_out),
        .yq_im(xq_im_out)
    );

    integer k;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            stage    <= 4'd0;
            pair_idx <= 4'd0;
            done_reg <= 1'b0;
            for (k = 0; k < N; k = k + 1) begin
                mem_real[k] <= {OUT_W{1'b0}};
                mem_imag[k] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_reg <= 1'b0;
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // Load input with bit-reversal permutation, sign-extend into OUT_W
                    for (k = 0; k < N; k = k + 1) begin
                        mem_real[rev_idx[k]] <= {{GAIN_W{data_real_in[k][DATA_W-1]}}, data_real_in[k]};
                        mem_imag[rev_idx[k]] <= {{GAIN_W{data_imag_in[k][DATA_W-1]}}, data_imag_in[k]};
                    end
                    stage    <= 4'd0;
                    pair_idx <= 4'd0;
                    state    <= S_BUTTERFLY;
                end

                S_BUTTERFLY: begin
                    mem_real[p_idx] <= xp_re_out;
                    mem_imag[p_idx] <= xp_im_out;
                    mem_real[q_idx] <= xq_re_out;
                    mem_imag[q_idx] <= xq_im_out;
                    state <= S_NEXT_PAIR;
                end

                S_NEXT_PAIR: begin
                    if (pair_idx == (N/2 - 1)) begin
                        pair_idx <= 4'd0;
                        if (stage == LOGN-1) begin
                            state <= S_SCALE;
                        end else begin
                            stage <= stage + 1'b1;
                            state <= S_BUTTERFLY;
                        end
                    end else begin
                        pair_idx <= pair_idx + 1'b1;
                        state <= S_BUTTERFLY;
                    end
                end

                S_SCALE: begin
                    // Divide all outputs by N (arithmetic right shift by log2N) only for IFFT
                    for (k = 0; k < N; k = k + 1) begin
                        if (mode) begin
                            mem_real[k] <= mem_real[k] >>> LOGN;
                            mem_imag[k] <= mem_imag[k] >>> LOGN;
                        end
                    end
                    state <= S_DONE;
                end

                S_DONE: begin
                    done_reg <= 1'b1;
                    if (start) begin
                        state <= S_LOAD;
                        done_reg <= 1'b0;
                    end else if (!start) begin
                        // Stay done until next start; but also handle direct restart via idle
                        state <= S_DONE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_GEN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

endmodule