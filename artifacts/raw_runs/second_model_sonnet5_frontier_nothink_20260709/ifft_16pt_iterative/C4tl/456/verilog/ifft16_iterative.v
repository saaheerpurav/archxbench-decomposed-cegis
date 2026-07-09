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

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam STAGES  = 4; // log2(16)

    // Internal storage - wide enough to avoid overflow through stages
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_RUN    = 3'd2;
    localparam S_SCALE  = 3'd3;
    localparam S_DONE   = 3'd4;

    reg [2:0] state;
    reg [2:0] stage;      // 1..STAGES
    reg [4:0] bfly_cnt;   // which butterfly within a stage (0..N/2-1)
    reg [4:0] out_idx;    // used for scale/output loop

    // bit reversal address
    wire [3:0] rev_addr [0:N-1];
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : REV
            bitrev_addr #(.W(4)) u_rev (
                .addr_in(gi[3:0]),
                .addr_out(rev_addr[gi])
            );
        end
    endgenerate

    // Stage index generation (combinational)
    wire [4:0] p_idx, q_idx;
    wire [3:0] tw_idx;

    stage_index_gen #(.N(N)) u_idx (
        .stage(stage),
        .bfly_cnt(bfly_cnt),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    // Twiddle ROM
    wire signed [COEFF_W-1:0] tw_cos, tw_sin;
    twiddle_rom #(.COEFF_W(COEFF_W)) u_rom (
        .idx(tw_idx),
        .cos_val(tw_cos),
        .sin_val(tw_sin)
    );

    // conjugate sin for IFFT mode (mode=1 => IFFT => use +sin as spec says conjugated stored table)
    // Per spec: IFFT uses conjugated twiddle -> sin negated relative to FFT table.
    // Our ROM stores FFT convention sin_q15[k]; for IFFT we need -sin (since conjugate negates imaginary part)
    // But per the butterfly equations given in spec (already written for IFFT with cos, sin direct),
    // the ROM values passed to butterfly should already represent the "positive-exp conjugated" table.
    // For FFT (mode=0), we need standard DIT-forward twiddle: cos - j*sin => use sin negated relative to IFFT form.
    wire signed [COEFF_W-1:0] eff_sin;
    assign eff_sin = mode ? tw_sin : -tw_sin;

    // Butterfly inputs (current p,q values)
    wire signed [OUT_W-1:0] xp_re, xp_im, xq_re, xq_im;
    assign xp_re = mem_real[p_idx];
    assign xp_im = mem_imag[p_idx];
    assign xq_re = mem_real[q_idx];
    assign xq_im = mem_imag[q_idx];

    wire signed [OUT_W-1:0] yp_re, yp_im, yq_re, yq_im;

    butterfly_unit #(.DATA_W(OUT_W), .COEFF_W(COEFF_W)) u_bfly (
        .xp_re(xp_re), .xp_im(xp_im),
        .xq_re(xq_re), .xq_im(xq_im),
        .cos_val(tw_cos), .sin_val(eff_sin),
        .yp_re(yp_re), .yp_im(yp_im),
        .yq_re(yq_re), .yq_im(yq_im)
    );

    // Scaling module (combinational) - divides by N when applicable
    wire signed [OUT_W-1:0] scaled_real, scaled_imag;
    scale_shift #(.W(OUT_W), .SHIFT(4)) u_scale (
        .in_real(mem_real[out_idx]),
        .in_imag(mem_imag[out_idx]),
        .do_scale(mode), // only scale for IFFT
        .out_real(scaled_real),
        .out_imag(scaled_imag)
    );

    // Output registers
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];
    reg done_r;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd1;
            bfly_cnt <= 5'd0;
            out_idx <= 5'd0;
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
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // load with bit-reversal permutation
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[rev_addr[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                        mem_imag[rev_addr[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                    end
                    stage <= 3'd1;
                    bfly_cnt <= 5'd0;
                    state <= S_RUN;
                end

                S_RUN: begin
                    // apply butterfly result for current p_idx,q_idx
                    mem_real[p_idx] <= yp_re;
                    mem_imag[p_idx] <= yp_im;
                    mem_real[q_idx] <= yq_re;
                    mem_imag[q_idx] <= yq_im;

                    if (bfly_cnt == (N/2 - 1)) begin
                        bfly_cnt <= 5'd0;
                        if (stage == STAGES) begin
                            state <= S_SCALE;
                            out_idx <= 5'd0;
                        end else begin
                            stage <= stage + 1;
                        end
                    end else begin
                        bfly_cnt <= bfly_cnt + 1;
                    end
                end

                S_SCALE: begin
                    out_real_r[out_idx] <= scaled_real;
                    out_imag_r[out_idx] <= scaled_imag;
                    if (out_idx == N-1) begin
                        state <= S_DONE;
                    end else begin
                        out_idx <= out_idx + 1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        state <= S_LOAD;
                        done_r <= 1'b0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    assign done = done_r;

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

endmodule