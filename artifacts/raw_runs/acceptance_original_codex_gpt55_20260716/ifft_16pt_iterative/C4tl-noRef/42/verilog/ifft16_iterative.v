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
    input mode,
    input signed [DATA_W-1:0] data_real_in [0:N-1],
    input signed [DATA_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output done
);

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam WORK_W = DATA_W + GAIN_W + 4;
    localparam LOGN   = 4;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [1:0] stage;
    reg [3:0] butterfly_idx;
    reg done_r;

    reg signed [WORK_W-1:0] mem_real [0:N-1];
    reg signed [WORK_W-1:0] mem_imag [0:N-1];

    wire [3:0] p_idx;
    wire [3:0] q_idx;
    wire [3:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [WORK_W-1:0] bf_p_real;
    wire signed [WORK_W-1:0] bf_p_imag;
    wire signed [WORK_W-1:0] bf_q_real;
    wire signed [WORK_W-1:0] bf_q_imag;

    assign done = done_r;

    fft16_addr_gen u_addr_gen (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .p_idx(p_idx),
        .q_idx(q_idx),
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
        .WORK_W(WORK_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .a_real(mem_real[p_idx]),
        .a_imag(mem_imag[p_idx]),
        .b_real(mem_real[q_idx]),
        .b_imag(mem_imag[q_idx]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .p_real(bf_p_real),
        .p_imag(bf_p_imag),
        .q_real(bf_q_real),
        .q_imag(bf_q_imag)
    );

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_scale
            wire signed [WORK_W-1:0] scaled_real_w;
            wire signed [WORK_W-1:0] scaled_imag_w;

            fft16_ifft_scale #(
                .WORK_W(WORK_W)
            ) u_scale_real (
                .din(mem_real[gi]),
                .dout(scaled_real_w)
            );

            fft16_ifft_scale #(
                .WORK_W(WORK_W)
            ) u_scale_imag (
                .din(mem_imag[gi]),
                .dout(scaled_imag_w)
            );

            assign data_real_out[gi] = scaled_real_w[OUT_W-1:0];
            assign data_imag_out[gi] = scaled_imag_w[OUT_W-1:0];
        end
    endgenerate

    function [3:0] bit_reverse4;
        input [3:0] value;
        begin
            bit_reverse4 = {value[0], value[1], value[2], value[3]};
        end
    endfunction

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 2'd0;
            butterfly_idx <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {WORK_W{1'b0}};
                mem_imag[i] <= {WORK_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    stage <= 2'd0;
                    butterfly_idx <= 4'd0;

                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[3:0])] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[3:0])] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (butterfly_idx == 4'd7) begin
                        butterfly_idx <= 4'd0;
                        if (stage == 2'd3) begin
                            state <= S_DONE;
                            done_r <= 1'b1;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 4'd1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        stage <= 2'd0;
                        butterfly_idx <= 4'd0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[3:0])] <= {{(WORK_W-DATA_W){data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[3:0])] <= {{(WORK_W-DATA_W){data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        state <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule