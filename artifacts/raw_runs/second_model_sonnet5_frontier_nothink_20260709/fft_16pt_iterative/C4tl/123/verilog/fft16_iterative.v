`timescale 1ns/1ps
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

// Working memory (wide enough to hold growth)
reg signed [OUT_W-1:0] mem_real [0:N-1];
reg signed [OUT_W-1:0] mem_imag [0:N-1];

// FSM states
localparam S_IDLE   = 3'd0;
localparam S_LOAD   = 3'd1;
localparam S_BFLY   = 3'd2;
localparam S_NEXT   = 3'd3;
localparam S_DONE   = 3'd4;

reg [2:0] state;
reg [2:0] stage;       // 0..LOGN-1
reg [3:0] bfly_cnt;    // 0..N/2-1 counts butterflies within a stage

reg mode_r;

// bit-reversal address wires
wire [3:0] rev_addr [0:N-1];
genvar gi;
generate
  for (gi = 0; gi < N; gi = gi + 1) begin : REV_GEN
    bitrev_addr #(.LOGN(LOGN)) u_rev (
      .addr_in(gi[3:0]),
      .addr_out(rev_addr[gi])
    );
  end
endgenerate

// Stage index generator (combinational)
wire [3:0] p_idx, q_idx, tw_idx;
stage_index_gen #(.N(N), .LOGN(LOGN)) u_idxgen (
    .stage(stage[1:0]),
    .bfly_cnt(bfly_cnt),
    .p_idx(p_idx),
    .q_idx(q_idx),
    .tw_idx(tw_idx)
);

// Twiddle ROM (combinational)
wire signed [COEFF_W-1:0] tw_cos, tw_sin;
twiddle_rom #(.COEFF_W(COEFF_W)) u_twrom (
    .index(tw_idx),
    .mode(mode_r),
    .cos_val(tw_cos),
    .sin_val(tw_sin)
);

// Butterfly unit (combinational)
wire signed [OUT_W-1:0] p_real_out, p_imag_out, q_real_out, q_imag_out;
butterfly_unit #(.OUT_W(OUT_W), .COEFF_W(COEFF_W)) u_bfly (
    .p_real(mem_real[p_idx]),
    .p_imag(mem_imag[p_idx]),
    .q_real(mem_real[q_idx]),
    .q_imag(mem_imag[q_idx]),
    .tw_cos(tw_cos),
    .tw_sin(tw_sin),
    .p_real_out(p_real_out),
    .p_imag_out(p_imag_out),
    .q_real_out(q_real_out),
    .q_imag_out(q_imag_out)
);

integer i;

always @(posedge clk) begin
    if (rst) begin
        state <= S_IDLE;
        stage <= 0;
        bfly_cnt <= 0;
        mode_r <= 0;
        for (i = 0; i < N; i = i + 1) begin
            mem_real[i] <= 0;
            mem_imag[i] <= 0;
        end
    end else begin
        case (state)
            S_IDLE: begin
                if (start) begin
                    mode_r <= mode;
                    state <= S_LOAD;
                end
            end

            S_LOAD: begin
                // Load with bit-reversed reordering
                for (i = 0; i < N; i = i + 1) begin
                    mem_real[i] <= {{GAIN_W{data_real_in[rev_addr[i]][DATA_W-1]}}, data_real_in[rev_addr[i]]};
                    mem_imag[i] <= {{GAIN_W{data_imag_in[rev_addr[i]][DATA_W-1]}}, data_imag_in[rev_addr[i]]};
                end
                stage <= 0;
                bfly_cnt <= 0;
                state <= S_BFLY;
            end

            S_BFLY: begin
                mem_real[p_idx] <= p_real_out;
                mem_imag[p_idx] <= p_imag_out;
                mem_real[q_idx] <= q_real_out;
                mem_imag[q_idx] <= q_imag_out;
                state <= S_NEXT;
            end

            S_NEXT: begin
                if (bfly_cnt == (N/2 - 1)) begin
                    bfly_cnt <= 0;
                    if (stage == LOGN-1) begin
                        state <= S_DONE;
                    end else begin
                        stage <= stage + 1;
                        state <= S_BFLY;
                    end
                end else begin
                    bfly_cnt <= bfly_cnt + 1;
                    state <= S_BFLY;
                end
            end

            S_DONE: begin
                if (!start) state <= S_DONE;
                if (start) begin
                    // allow re-trigger
                end
            end

            default: state <= S_IDLE;
        endcase

        if (state == S_DONE && start) begin
            mode_r <= mode;
            state <= S_LOAD;
        end
    end
end

assign done = (state == S_DONE);

generate
  for (gi = 0; gi < N; gi = gi + 1) begin : OUT_GEN
    assign data_real_out[gi] = mem_real[gi];
    assign data_imag_out[gi] = mem_imag[gi];
  end
endgenerate

endmodule