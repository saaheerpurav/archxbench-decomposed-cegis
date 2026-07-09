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

    // Working memory (extra headroom bits for growth across stages)
    reg signed [OUT_W-1:0] mem_re [0:N-1];
    reg signed [OUT_W-1:0] mem_im [0:N-1];

    // Twiddle ROM (Q1.15), base table k=0..8, extended to k=0..15 via symmetry
    function signed [COEFF_W-1:0] twcos;
        input [3:0] k;
        begin
            case (k)
                4'd0: twcos = 16'sd32767;
                4'd1: twcos = 16'sd30274;
                4'd2: twcos = 16'sd23170;
                4'd3: twcos = 16'sd12540;
                4'd4: twcos = 16'sd0;
                4'd5: twcos = -16'sd12540;
                4'd6: twcos = -16'sd23170;
                4'd7: twcos = -16'sd30274;
                4'd8: twcos = -16'sd32768;
                4'd9: twcos = -16'sd30274;
                4'd10: twcos = -16'sd23170;
                4'd11: twcos = -16'sd12540;
                4'd12: twcos = 16'sd0;
                4'd13: twcos = 16'sd12540;
                4'd14: twcos = 16'sd23170;
                4'd15: twcos = 16'sd30274;
                default: twcos = 16'sd0;
            endcase
        end
    endfunction

    function signed [COEFF_W-1:0] twsin_base;
        input [3:0] k;
        begin
            case (k)
                4'd0: twsin_base = 16'sd0;
                4'd1: twsin_base = 16'sd12540;
                4'd2: twsin_base = 16'sd23170;
                4'd3: twsin_base = 16'sd30274;
                4'd4: twsin_base = 16'sd32767;
                4'd5: twsin_base = 16'sd30274;
                4'd6: twsin_base = 16'sd23170;
                4'd7: twsin_base = 16'sd12540;
                4'd8: twsin_base = 16'sd0;
                4'd9: twsin_base = -16'sd12540;
                4'd10: twsin_base = -16'sd23170;
                4'd11: twsin_base = -16'sd30274;
                4'd12: twsin_base = -16'sd32767;
                4'd13: twsin_base = -16'sd30274;
                4'd14: twsin_base = -16'sd23170;
                4'd15: twsin_base = -16'sd12540;
                default: twsin_base = 16'sd0;
            endcase
        end
    endfunction

    // For IFFT (mode=1), use conjugated twiddle -> negate sin (per spec: "for IFFT negate sin_q15 to conjugate")
    // But note the spec's butterfly convention for IFFT already says twiddle_w = cos + j*sin (positive-exp, conjugated)
    // meaning the "conjugation" was already baked into using +sin instead of -sin relative to forward FFT.
    // So for IFFT we use twsin_base directly (not negated again), since forward would use -sin.
    function signed [COEFF_W-1:0] twsin;
        input [3:0] k;
        input m; // mode
        begin
            if (m)
                twsin = twsin_base(k); // IFFT: conjugated (already accounted per spec)
            else
                twsin = -twsin_base(k); // FFT: standard negative exponent
        end
    endfunction

    // Bit reversal for 4-bit index
    function [3:0] bitrev4;
        input [3:0] idx;
        begin
            bitrev4 = {idx[0], idx[1], idx[2], idx[3]};
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
    reg [1:0] stage;      // 0..3
    reg [3:0] group;      // which group within stage (butterflies iterate globally)
    reg [3:0] bfly_idx;   // butterfly index within stage: 0..7 total per stage

    reg mode_r;
    reg [3:0] scale_idx;

    reg done_r;
    assign done = done_r;

    integer gi;
    generate
        genvar gv;
        for (gv = 0; gv < N; gv = gv + 1) begin : OUT_ASSIGN
            assign data_real_out[gv] = mem_re[gv];
            assign data_imag_out[gv] = mem_im[gv];
        end
    endgenerate

    // Butterfly computation signals
    reg [3:0] p_idx, q_idx;
    reg [3:0] tw_idx;
    reg signed [OUT_W-1:0] xp_re, xp_im, xq_re, xq_im;
    reg signed [COEFF_W-1:0] c_val, s_val;

    wire signed [OUT_W+COEFF_W-1:0] mult_rr = xq_re * c_val;
    wire signed [OUT_W+COEFF_W-1:0] mult_ii = xq_im * s_val;
    wire signed [OUT_W+COEFF_W-1:0] mult_ri = xq_re * s_val;
    wire signed [OUT_W+COEFF_W-1:0] mult_ir = xq_im * c_val;

    wire signed [OUT_W+COEFF_W:0] tr_full = mult_rr - mult_ii + (1 <<< 14);
    wire signed [OUT_W+COEFF_W:0] ti_full = mult_ri + mult_ir + (1 <<< 14);

    wire signed [OUT_W-1:0] tr = tr_full >>> 15;
    wire signed [OUT_W-1:0] ti = ti_full >>> 15;

    // Stage parameters: for stage s (0-indexed), butterfly span = 2^s, group size = 2^(s+1)
    // total butterflies per stage = N/2 = 8
    // We iterate bfly_idx from 0 to 7, and compute p,q,tw from it.

    reg [3:0] span;      // 2^stage
    reg [3:0] gsize;      // 2^(stage+1)
    reg [3:0] grp_num;
    reg [3:0] pos_in_grp;

    always @(*) begin
        span = (4'd1 << stage);
        gsize = (span << 1);
        grp_num = bfly_idx / span;      // which group
        pos_in_grp = bfly_idx % span;   // position within group's half
        p_idx = grp_num * gsize + pos_in_grp;
        q_idx = p_idx + span;
        // twiddle index: pos_in_grp * (N / gsize)
        tw_idx = pos_in_grp * (N / gsize);
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done_r <= 1'b0;
            stage <= 0;
            bfly_idx <= 0;
            scale_idx <= 0;
            mode_r <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        mode_r <= mode;
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // Load bit-reversed input into mem
                    for (gi = 0; gi < N; gi = gi + 1) begin
                        mem_re[gi] <= {{GAIN_W{data_real_in[bitrev4(gi[3:0])][DATA_W-1]}}, data_real_in[bitrev4(gi[3:0])]};
                        mem_im[gi] <= {{GAIN_W{data_imag_in[bitrev4(gi[3:0])][DATA_W-1]}}, data_imag_in[bitrev4(gi[3:0])]};
                    end
                    stage <= 0;
                    bfly_idx <= 0;
                    state <= S_BFLY;
                end

                S_BFLY: begin
                    // Latch operands and coefficients this cycle, compute next cycle
                    xp_re <= mem_re[p_idx];
                    xp_im <= mem_im[p_idx];
                    xq_re <= mem_re[q_idx];
                    xq_im <= mem_im[q_idx];
                    c_val <= twcos(tw_idx);
                    s_val <= twsin(tw_idx, mode_r);
                    state <= S_NEXT;
                end

                S_NEXT: begin
                    // Write results using tr/ti computed from latched values
                    mem_re[p_idx] <= xp_re + tr;
                    mem_im[p_idx] <= xp_im + ti;
                    mem_re[q_idx] <= xp_re - tr;
                    mem_im[q_idx] <= xp_im - ti;

                    if (bfly_idx == (N/2 - 1)) begin
                        bfly_idx <= 0;
                        if (stage == LOGN - 1) begin
                            if (mode_r) begin
                                scale_idx <= 0;
                                state <= S_SCALE;
                            end else begin
                                state <= S_DONE;
                            end
                        end else begin
                            stage <= stage + 1;
                            state <= S_BFLY;
                        end
                    end else begin
                        bfly_idx <= bfly_idx + 1;
                        state <= S_BFLY;
                    end
                end

                S_SCALE: begin
                    mem_re[scale_idx] <= mem_re[scale_idx] >>> 4;
                    mem_im[scale_idx] <= mem_im[scale_idx] >>> 4;
                    if (scale_idx == N-1) begin
                        state <= S_DONE;
                    end else begin
                        scale_idx <= scale_idx + 1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        // allow restart
                    end else if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule