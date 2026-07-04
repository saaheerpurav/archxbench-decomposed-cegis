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
    input mode,
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOGN  = 4;

    localparam S_IDLE = 2'd0;
    localparam S_LOAD = 2'd1;
    localparam S_RUN  = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    reg mode_reg;
    reg [LOGN-1:0] load_idx;
    reg [1:0] stage;
    reg [2:0] bf_idx;
    reg done_reg;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOGN-1:0] bitrev_idx;
    wire [LOGN-1:0] p_idx;
    wire [LOGN-1:0] q_idx;
    wire [LOGN-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    integer i;

    assign done = done_reg;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    fft16_bit_reverse #(
        .LOGN(LOGN)
    ) u_bit_reverse (
        .index_in(load_idx),
        .index_out(bitrev_idx)
    );

    fft16_stage_index #(
        .N(N),
        .LOGN(LOGN)
    ) u_stage_index (
        .stage(stage),
        .butterfly_index(bf_idx),
        .p_index(p_idx),
        .q_index(q_idx),
        .twiddle_index(tw_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .index(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode(mode_reg),
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

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            mode_reg <= 1'b0;
            load_idx <= {LOGN{1'b0}};
            stage <= 2'd0;
            bf_idx <= 3'd0;
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
                        mode_reg <= mode;
                        load_idx <= {LOGN{1'b0}};
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    mem_real[bitrev_idx] <= {{GAIN_W{data_real_in[load_idx][DATA_W-1]}}, data_real_in[load_idx]};
                    mem_imag[bitrev_idx] <= {{GAIN_W{data_imag_in[load_idx][DATA_W-1]}}, data_imag_in[load_idx]};

                    if (load_idx == N-1) begin
                        stage <= 2'd0;
                        bf_idx <= 3'd0;
                        state <= S_RUN;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if ((stage == LOGN-1) && (bf_idx == (N/2)-1)) begin
                        if (mode_reg) begin
                            for (i = 0; i < N; i = i + 1) begin
                                mem_real[i] <= mem_real[i] >>> LOGN;
                                mem_imag[i] <= mem_imag[i] >>> LOGN;
                            end
                        end
                        done_reg <= 1'b1;
                        state <= S_DONE;
                    end else if (bf_idx == (N/2)-1) begin
                        bf_idx <= 3'd0;
                        stage <= stage + 1'b1;
                    end else begin
                        bf_idx <= bf_idx + 1'b1;
                    end
                end

                S_DONE: begin
                    done_reg <= 1'b1;
                    if (start) begin
                        done_reg <= 1'b0;
                        mode_reg <= mode;
                        load_idx <= {LOGN{1'b0}};
                        state <= S_LOAD;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    done_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule