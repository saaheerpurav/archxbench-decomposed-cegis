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
    localparam LOGN = 4; // log2(16)

    // Memory arrays holding intermediate (and final) results, sign-extended to OUT_W
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_RUN    = 3'd2;
    localparam S_DONE   = 3'd3;

    reg [2:0] state;
    reg [1:0] stage;       // 0..3 for LOGN=4
    reg [3:0] pair_idx;    // 0..(N/2-1) = 0..7 iteration index within a stage
    reg done_reg;

    // Bit reversal address for loading
    wire [3:0] bitrev_idx [0:N-1];
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin: BR_GEN
            bitrev_addr #(.LOGN(LOGN)) u_br (
                .idx_in  (gi[3:0]),
                .idx_out (bitrev_idx[gi])
            );
        end
    endgenerate

    // Stage address generation (combinational) - computes p, q indices and twiddle index
    wire [3:0] p_idx, q_idx, tw_idx;
    stage_addr_gen #(.N(N), .LOGN(LOGN)) u_addr_gen (
        .stage    (stage),
        .pair_idx (pair_idx),
        .p_idx    (p_idx),
        .q_idx    (q_idx),
        .tw_idx   (tw_idx)
    );

    // Twiddle ROM lookup (combinational), handle symmetry for idx 0..15
    wire signed [COEFF_W-1:0] cos_val, sin_val;
    // Map tw_idx (0..15) into base index (0..8) and sign/swap logic handled inside rom wrapper
    twiddle_rom #(.COEFF_W(COEFF_W)) u_rom (
        .k       (tw_idx),
        .cos_out (cos_val),
        .sin_out (sin_val)
    );

    // Butterfly inputs
    wire signed [OUT_W-1:0] bf_p_re_in, bf_p_im_in, bf_q_re_in, bf_q_im_in;
    assign bf_p_re_in = mem_real[p_idx];
    assign bf_p_im_in = mem_imag[p_idx];
    assign bf_q_re_in = mem_real[q_idx];
    assign bf_q_im_in = mem_imag[q_idx];

    wire signed [OUT_W-1:0] bf_p_re_out, bf_p_im_out, bf_q_re_out, bf_q_im_out;

    bfly_unit #(
        .OUT_W   (OUT_W),
        .COEFF_W (COEFF_W)
    ) u_bfly (
        .mode     (mode),
        .p_re_in  (bf_p_re_in),
        .p_im_in  (bf_p_im_in),
        .q_re_in  (bf_q_re_in),
        .q_im_in  (bf_q_im_in),
        .cos_val  (cos_val),
        .sin_val  (sin_val),
        .p_re_out (bf_p_re_out),
        .p_im_out (bf_p_im_out),
        .q_re_out (bf_q_re_out),
        .q_im_out (bf_q_im_out)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            stage    <= 2'd0;
            pair_idx <= 4'd0;
            done_reg <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
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
                    // Load with bit-reversed ordering, sign-extend to OUT_W
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                        mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                    end
                    stage    <= 2'd0;
                    pair_idx <= 4'd0;
                    state    <= S_RUN;
                end

                S_RUN: begin
                    // Perform butterfly using current p_idx/q_idx/tw_idx (combinationally computed)
                    mem_real[p_idx] <= bf_p_re_out;
                    mem_imag[p_idx] <= bf_p_im_out;
                    mem_real[q_idx] <= bf_q_re_out;
                    mem_imag[q_idx] <= bf_q_im_out;

                    if (pair_idx == (N/2 - 1)) begin
                        pair_idx <= 4'd0;
                        if (stage == LOGN-1) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        pair_idx <= pair_idx + 4'd1;
                    end
                end

                S_DONE: begin
                    done_reg <= 1'b1;
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    assign done = done_reg;

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin: OUT_GEN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

endmodule