module fft16_iterative #(
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

    // Working memory (signed, OUT_W bits to accommodate growth)
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // Twiddle ROM: cos_q15[k], sin_q15[k] for k=0..8
    function signed [COEFF_W-1:0] cos_q15;
        input [3:0] k;
        reg [3:0] kk;
        begin
            kk = (k[3]) ? (16 - k) : k; // fold to 0..8, cos symmetric
            case (kk)
                4'd0: cos_q15 = 16'sd32767;
                4'd1: cos_q15 = 16'sd30274;
                4'd2: cos_q15 = 16'sd23170;
                4'd3: cos_q15 = 16'sd12540;
                4'd4: cos_q15 = 16'sd0;
                4'd5: cos_q15 = -16'sd12540;
                4'd6: cos_q15 = -16'sd23170;
                4'd7: cos_q15 = -16'sd30274;
                4'd8: cos_q15 = -16'sd32768;
                default: cos_q15 = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] sin_q15;
        input [3:0] k;
        reg [3:0] kk;
        reg sign_neg;
        reg signed [COEFF_W-1:0] base;
        begin
            if (k <= 4'd8) begin
                kk = k;
                sign_neg = 1'b0;
            end else begin
                kk = 16 - k;
                sign_neg = 1'b1;
            end
            case (kk)
                4'd0: base = 16'sd0;
                4'd1: base = 16'sd12540;
                4'd2: base = 16'sd23170;
                4'd3: base = 16'sd30274;
                4'd4: base = 16'sd32767;
                4'd5: base = 16'sd30274;
                4'd6: base = 16'sd23170;
                4'd7: base = 16'sd12540;
                4'd8: base = 16'sd0;
                default: base = 16'sd0;
            endcase
            sin_q15 = sign_neg ? (-base) : base;
        end
    endfunction

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_BFLY   = 3'd2;
    localparam S_NEXT   = 3'd3;
    localparam S_SCALE  = 3'd4;
    localparam S_DONE   = 3'd5;

    reg [2:0] state;
    reg mode_r;

    // Stage/group/index counters - widened to avoid truncation (size can be 16)
    reg [2:0] stage;        // 0..3
    reg [5:0] group_start;  // j (needs range 0..15, but arithmetic with size up to 16)
    reg [3:0] k_idx;        // k within half
    reg [5:0] size;         // 2^(stage+1), up to 16
    reg [5:0] half;         // size/2, up to 8
    reg [5:0] tw_step;      // N/size

    reg [3:0] bitrev_idx;

    function [3:0] bit_reverse4;
        input [3:0] x;
        begin
            bit_reverse4 = {x[0], x[1], x[2], x[3]};
        end
    endfunction

    reg done_r;
    assign done = done_r;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin: OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    // Butterfly combinational computation
    reg [3:0] p_idx, q_idx;
    reg [3:0] tw_idx;
    reg signed [COEFF_W-1:0] c_val, s_val;
    reg signed [OUT_W-1:0] xp_re, xp_im, xq_re, xq_im;
    reg signed [OUT_W+COEFF_W-1:0] mul1, mul2, mul3, mul4;
    reg signed [OUT_W+COEFF_W-1:0] sum_r, sum_i;
    reg signed [OUT_W-1:0] tr_real, tr_imag;

    integer scale_i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done_r <= 1'b0;
            stage <= 0;
            group_start <= 0;
            k_idx <= 0;
            bitrev_idx <= 0;
            mode_r <= 0;
            scale_i <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        mode_r <= mode;
                        bitrev_idx <= 0;
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // load bit-reversed order, sign-extend to OUT_W
                    mem_real[bitrev_idx] <= {{GAIN_W{data_real_in[bit_reverse4(bitrev_idx)][DATA_W-1]}}, data_real_in[bit_reverse4(bitrev_idx)]};
                    mem_imag[bitrev_idx] <= {{GAIN_W{data_imag_in[bit_reverse4(bitrev_idx)][DATA_W-1]}}, data_imag_in[bit_reverse4(bitrev_idx)]};
                    if (bitrev_idx == N-1) begin
                        stage <= 0;
                        group_start <= 0;
                        k_idx <= 0;
                        state <= S_BFLY;
                    end else begin
                        bitrev_idx <= bitrev_idx + 1;
                    end
                end

                S_BFLY: begin
                    // perform one butterfly using combinational values computed below
                    mem_real[p_idx] <= xp_re + tr_real;
                    mem_imag[p_idx] <= xp_im + tr_imag;
                    mem_real[q_idx] <= xp_re - tr_real;
                    mem_imag[q_idx] <= xp_im - tr_imag;
                    state <= S_NEXT;
                end

                S_NEXT: begin
                    if (k_idx == half - 1) begin
                        k_idx <= 0;
                        if (group_start + size >= N) begin
                            // move to next stage
                            group_start <= 0;
                            if (stage == LOGN-1) begin
                                // finished all stages
                                if (mode_r) begin
                                    scale_i <= 0;
                                    state <= S_SCALE;
                                end else begin
                                    state <= S_DONE;
                                end
                            end else begin
                                stage <= stage + 1;
                                state <= S_BFLY;
                            end
                        end else begin
                            group_start <= group_start + size;
                            state <= S_BFLY;
                        end
                    end else begin
                        k_idx <= k_idx + 1;
                        state <= S_BFLY;
                    end
                end

                S_SCALE: begin
                    // divide by 16 (arithmetic shift right by 4) with rounding
                    mem_real[scale_i[3:0]] <= (mem_real[scale_i[3:0]] + {{(OUT_W-4){1'b0}}, 4'd8}) >>> 4;
                    mem_imag[scale_i[3:0]] <= (mem_imag[scale_i[3:0]] + {{(OUT_W-4){1'b0}}, 4'd8}) >>> 4;
                    if (scale_i == N-1) begin
                        state <= S_DONE;
                    end else begin
                        scale_i <= scale_i + 1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (!start) begin
                        // stay done; only leave when a new start pulse arrives
                        state <= S_DONE;
                    end
                    if (start) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // Combinational: compute stage-derived parameters and butterfly math
    always @(*) begin
        size    = (6'd1 << (stage+1));
        half    = size >> 1;
        tw_step = (N >> (stage+1));

        p_idx = group_start[3:0] + k_idx;
        q_idx = group_start[3:0] + k_idx + half[3:0];
        tw_idx = (k_idx * tw_step[3:0]) & 4'hF;

        c_val = cos_q15(tw_idx[3:0]);
        s_val = mode_r ? (-sin_q15(tw_idx[3:0])) : sin_q15(tw_idx[3:0]);

        xp_re = mem_real[p_idx];
        xp_im = mem_imag[p_idx];
        xq_re = mem_real[q_idx];
        xq_im = mem_imag[q_idx];

        // tr_real = (xq_re*c + xq_im*s + 2^14) >> 15
        // tr_imag = (xq_im*c - xq_re*s + 2^14) >> 15
        mul1 = xq_re * c_val;
        mul2 = xq_im * s_val;
        mul3 = xq_im * c_val;
        mul4 = xq_re * s_val;

        sum_r = mul1 + mul2 + (1 << 14);
        sum_i = mul3 - mul4 + (1 << 14);

        tr_real = sum_r >>> 15;
        tr_imag = sum_i >>> 15;
    end

endmodule