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
    localparam STAGES = 4;
    localparam BF_PER_STAGE = N/2;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg mode_reg;
    reg [2:0] stage;
    reg [3:0] bfly_idx;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] idx_p;
    wire [3:0] idx_q;
    wire [3:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] y_p_real;
    wire signed [OUT_W-1:0] y_p_imag;
    wire signed [OUT_W-1:0] y_q_real;
    wire signed [OUT_W-1:0] y_q_imag;

    genvar gi;

    function [3:0] bit_reverse4;
        input [3:0] value;
        begin
            bit_reverse4 = {value[0], value[1], value[2], value[3]};
        end
    endfunction

    fft16_index_gen #(
        .N(N)
    ) u_index_gen (
        .stage(stage),
        .bfly_idx(bfly_idx),
        .idx_p(idx_p),
        .idx_q(idx_q),
        .tw_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .tw_idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode(mode_reg),
        .a_real(mem_real[idx_p]),
        .a_imag(mem_imag[idx_p]),
        .b_real(mem_real[idx_q]),
        .b_imag(mem_imag[idx_q]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y_a_real(y_p_real),
        .y_a_imag(y_p_imag),
        .y_b_real(y_q_real),
        .y_b_imag(y_q_imag)
    );

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_outputs
            fft16_output_scale #(
                .IN_W(OUT_W)
            ) u_output_scale (
                .mode(mode_reg),
                .in_real(mem_real[gi]),
                .in_imag(mem_imag[gi]),
                .out_real(data_real_out[gi]),
                .out_imag(data_imag_out[gi])
            );
        end
    endgenerate

    assign done = (state == S_DONE);

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            mode_reg <= 1'b0;
            stage <= 3'd0;
            bfly_idx <= 4'd0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage <= 3'd0;
                        bfly_idx <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= {{GAIN_W{data_real_in[bit_reverse4(i[3:0])][DATA_W-1]}}, data_real_in[bit_reverse4(i[3:0])]};
                            mem_imag[i] <= {{GAIN_W{data_imag_in[bit_reverse4(i[3:0])][DATA_W-1]}}, data_imag_in[bit_reverse4(i[3:0])]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[idx_p] <= y_p_real;
                    mem_imag[idx_p] <= y_p_imag;
                    mem_real[idx_q] <= y_q_real;
                    mem_imag[idx_q] <= y_q_imag;

                    if (bfly_idx == BF_PER_STAGE-1) begin
                        bfly_idx <= 4'd0;
                        if (stage == STAGES-1) begin
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        bfly_idx <= bfly_idx + 4'd1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        mode_reg <= mode;
                        stage <= 3'd0;
                        bfly_idx <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[i] <= {{GAIN_W{data_real_in[bit_reverse4(i[3:0])][DATA_W-1]}}, data_real_in[bit_reverse4(i[3:0])]};
                            mem_imag[i] <= {{GAIN_W{data_imag_in[bit_reverse4(i[3:0])][DATA_W-1]}}, data_imag_in[bit_reverse4(i[3:0])]};
                        end
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule