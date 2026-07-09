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

    // Memory arrays (wide enough to hold growth)
    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    // Bit reversed address wires
    wire [3:0] bitrev_addr_w [0:N-1];
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : BR_GEN
            bitrev_addr #(.LOGN(LOGN)) u_br (
                .idx(gi[3:0]),
                .rev(bitrev_addr_w[gi])
            );
        end
    endgenerate

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_STAGE  = 3'd2;
    localparam S_SCALE  = 3'd3;
    localparam S_DONE   = 3'd4;

    reg [2:0] state;
    reg [3:0] stage;      // 0..LOGN-1
    reg [3:0] bfy_cnt;    // which butterfly within stage, 0..N/2-1
    reg [3:0] scale_idx;
    reg mode_r;

    // Stage index generation (combinational)
    wire [3:0] p_idx, q_idx, tw_idx;
    stage_index_gen #(.N(N), .LOGN(LOGN)) u_idxgen (
        .stage(stage),
        .bfy_cnt(bfy_cnt),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    // Twiddle ROM
    wire signed [COEFF_W-1:0] cos_val, sin_val;
    twiddle_rom #(.COEFF_W(COEFF_W)) u_rom (
        .k(tw_idx),
        .cos_val(cos_val),
        .sin_val(sin_val)
    );

    // Butterfly unit
    wire signed [OUT_W-1:0] p_real_in, p_imag_in, q_real_in, q_imag_in;
    wire signed [OUT_W-1:0] p_real_out, p_imag_out, q_real_out, q_imag_out;

    assign p_real_in = mem_real[p_idx];
    assign p_imag_in = mem_imag[p_idx];
    assign q_real_in = mem_real[q_idx];
    assign q_imag_in = mem_imag[q_idx];

    butterfly_unit #(.OUT_W(OUT_W), .COEFF_W(COEFF_W)) u_bfly (
        .mode(mode_r),
        .p_real(p_real_in),
        .p_imag(p_imag_in),
        .q_real(q_real_in),
        .q_imag(q_imag_in),
        .cos_val(cos_val),
        .sin_val(sin_val),
        .p_real_out(p_real_out),
        .p_imag_out(p_imag_out),
        .q_real_out(q_real_out),
        .q_imag_out(q_imag_out)
    );

    integer li;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            stage    <= 0;
            bfy_cnt  <= 0;
            scale_idx <= 0;
            mode_r   <= 0;
            for (li = 0; li < N; li = li + 1) begin
                mem_real[li] <= 0;
                mem_imag[li] <= 0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        mode_r <= mode;
                        state  <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    // load with bit-reversal, sign-extend to OUT_W
                    for (li = 0; li < N; li = li + 1) begin
                        mem_real[bitrev_addr_w[li]] <= {{GAIN_W{data_real_in[li][DATA_W-1]}}, data_real_in[li]};
                        mem_imag[bitrev_addr_w[li]] <= {{GAIN_W{data_imag_in[li][DATA_W-1]}}, data_imag_in[li]};
                    end
                    stage   <= 0;
                    bfy_cnt <= 0;
                    state   <= S_STAGE;
                end

                S_STAGE: begin
                    // write back butterfly results
                    mem_real[p_idx] <= p_real_out;
                    mem_imag[p_idx] <= p_imag_out;
                    mem_real[q_idx] <= q_real_out;
                    mem_imag[q_idx] <= q_imag_out;

                    if (bfy_cnt == (N/2 - 1)) begin
                        bfy_cnt <= 0;
                        if (stage == LOGN-1) begin
                            stage <= 0;
                            if (mode_r) begin
                                scale_idx <= 0;
                                state <= S_SCALE;
                            end else begin
                                state <= S_DONE;
                            end
                        end else begin
                            stage <= stage + 1;
                        end
                    end else begin
                        bfy_cnt <= bfy_cnt + 1;
                    end
                end

                S_SCALE: begin
                    // divide by N=16 (shift right by 4), rounding toward -inf is fine
                    mem_real[scale_idx] <= mem_real[scale_idx] >>> 4;
                    mem_imag[scale_idx] <= mem_imag[scale_idx] >>> 4;
                    if (scale_idx == N-1) begin
                        state <= S_DONE;
                    end else begin
                        scale_idx <= scale_idx + 1;
                    end
                end

                S_DONE: begin
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    assign done = (state == S_DONE);

    genvar go;
    generate
        for (go = 0; go < N; go = go + 1) begin : OUT_GEN
            assign data_real_out[go] = mem_real[go];
            assign data_imag_out[go] = mem_imag[go];
        end
    endgenerate

endmodule