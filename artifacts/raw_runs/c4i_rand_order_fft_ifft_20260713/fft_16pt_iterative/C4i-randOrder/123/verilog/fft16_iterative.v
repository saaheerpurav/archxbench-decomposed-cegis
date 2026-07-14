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
    localparam LOG_N = 4;

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [LOG_N-1:0] stage;
    reg [LOG_N-1:0] butterfly_index;
    reg mode_reg;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOG_N-1:0] load_addr [0:N-1];

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_BITREV
            fft16_bit_reverse #(
                .ADDR_W(LOG_N)
            ) u_bit_reverse (
                .addr_in (gi[LOG_N-1:0]),
                .addr_out(load_addr[gi])
            );
        end
    endgenerate

    wire [LOG_N-1:0] pair_p;
    wire [LOG_N-1:0] pair_q;
    wire [LOG_N-1:0] twiddle_index;
    wire last_butterfly;
    wire last_stage;

    fft16_stage_indexer #(
        .N(N),
        .LOG_N(LOG_N)
    ) u_stage_indexer (
        .stage          (stage),
        .butterfly_index(butterfly_index),
        .p_addr         (pair_p),
        .q_addr         (pair_q),
        .twiddle_index  (twiddle_index),
        .last_butterfly (last_butterfly),
        .last_stage     (last_stage)
    );

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin_pos;

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .index (twiddle_index),
        .cos_q (tw_cos),
        .sin_q (tw_sin_pos)
    );

    wire signed [COEFF_W-1:0] tw_sin_eff;
    assign tw_sin_eff = mode_reg ? -tw_sin_pos : tw_sin_pos;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real (mem_real[pair_p]),
        .a_imag (mem_imag[pair_p]),
        .b_real (mem_real[pair_q]),
        .b_imag (mem_imag[pair_q]),
        .tw_cos (tw_cos),
        .tw_sin (tw_sin_eff),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUTPUTS
            fft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_output_scale_real (
                .value_in (mem_real[gi]),
                .ifft_mode(mode_reg),
                .value_out(data_real_out[gi])
            );

            fft16_output_scale #(
                .IN_W(OUT_W),
                .SHIFT(GAIN_W)
            ) u_output_scale_imag (
                .value_in (mem_imag[gi]),
                .ifft_mode(mode_reg),
                .value_out(data_imag_out[gi])
            );
        end
    endgenerate

    assign done = (state == S_DONE);

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= {LOG_N{1'b0}};
            butterfly_index <= {LOG_N{1'b0}};
            mode_reg <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage <= {LOG_N{1'b0}};
                        butterfly_index <= {LOG_N{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_addr[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_addr[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    mem_real[pair_p] <= bf_p_real;
                    mem_imag[pair_p] <= bf_p_imag;
                    mem_real[pair_q] <= bf_q_real;
                    mem_imag[pair_q] <= bf_q_imag;

                    if (last_butterfly) begin
                        butterfly_index <= {LOG_N{1'b0}};
                        if (last_stage) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 1'b1;
                        end
                    end else begin
                        butterfly_index <= butterfly_index + 1'b1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage <= {LOG_N{1'b0}};
                        butterfly_index <= {LOG_N{1'b0}};
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[load_addr[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[load_addr[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_CALC;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule