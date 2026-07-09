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
    localparam STAGES = 4; // log2(16)

    // Working memory - wide enough to avoid overflow through stages
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD    = 3'd1;
    localparam S_BFLY    = 3'd2;
    localparam S_NEXT    = 3'd3;
    localparam S_SCALE   = 3'd4;
    localparam S_DONE    = 3'd5;

    reg [2:0] state;
    reg [2:0] stage_cnt;      // 0..3
    reg [3:0] bfly_cnt;       // 0..7 within a stage

    reg done_r;
    assign done = done_r;

    // Bit reversal address (combinational sub-module)
    wire [3:0] bitrev_addr_w [0:N-1];
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : BITREV_GEN
            bitrev_addr #(.WIDTH(4)) u_bitrev (
                .addr_in(gi[3:0]),
                .addr_out(bitrev_addr_w[gi])
            );
        end
    endgenerate

    // Stage index generator (combinational)
    wire [3:0] idx_p, idx_q, tw_idx;
    stage_index_gen #(.N(N), .STAGES(STAGES)) u_stage_idx (
        .stage(stage_cnt),
        .bfly_num(bfly_cnt),
        .idx_p(idx_p),
        .idx_q(idx_q),
        .tw_idx(tw_idx)
    );

    // Twiddle ROM (combinational)
    wire signed [COEFF_W-1:0] cos_val, sin_val;
    twiddle_rom #(.COEFF_W(COEFF_W)) u_twiddle (
        .idx(tw_idx),
        .cos_val(cos_val),
        .sin_val(sin_val)
    );

    // Sign of sin for IFFT conjugation: mode=1 (IFFT) uses table as-is (per spec,
    // conjugated table always used since mode should be tied to 1). We apply
    // the sign flip explicitly based on mode for generality.
    wire signed [COEFF_W-1:0] sin_eff = mode ? sin_val : -sin_val;

    // Butterfly unit (combinational)
    wire signed [OUT_W-1:0] p_re_in, p_im_in, q_re_in, q_im_in;
    wire signed [OUT_W-1:0] p_re_out, p_im_out, q_re_out, q_im_out;

    assign p_re_in = mem_real[idx_p];
    assign p_im_in = mem_imag[idx_p];
    assign q_re_in = mem_real[idx_q];
    assign q_im_in = mem_imag[idx_q];

    butterfly_unit #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .p_re_in(p_re_in),
        .p_im_in(p_im_in),
        .q_re_in(q_re_in),
        .q_im_in(q_im_in),
        .cos_val(cos_val),
        .sin_val(sin_eff),
        .p_re_out(p_re_out),
        .p_im_out(p_im_out),
        .q_re_out(q_re_out),
        .q_im_out(q_im_out)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            stage_cnt <= 0;
            bfly_cnt  <= 0;
            done_r    <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // Load with bit-reversal permutation, sign-extend to OUT_W
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[bitrev_addr_w[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                        mem_imag[bitrev_addr_w[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                    end
                    stage_cnt <= 0;
                    bfly_cnt  <= 0;
                    state     <= S_BFLY;
                end

                S_BFLY: begin
                    mem_real[idx_p] <= p_re_out;
                    mem_imag[idx_p] <= p_im_out;
                    mem_real[idx_q] <= q_re_out;
                    mem_imag[idx_q] <= q_im_out;
                    state <= S_NEXT;
                end

                S_NEXT: begin
                    if (bfly_cnt == (N/2 - 1)) begin
                        bfly_cnt <= 0;
                        if (stage_cnt == STAGES - 1) begin
                            state <= S_SCALE;
                        end else begin
                            stage_cnt <= stage_cnt + 1;
                            state <= S_BFLY;
                        end
                    end else begin
                        bfly_cnt <= bfly_cnt + 1;
                        state <= S_BFLY;
                    end
                end

                S_SCALE: begin
                    if (mode) begin
                        // divide by N=16 -> arithmetic shift right 4
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= mem_real[i] >>> 4;
                            mem_imag[i] <= mem_imag[i] >>> 4;
                        end
                    end
                    state <= S_DONE;
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (!start) begin
                        state <= S_IDLE;
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