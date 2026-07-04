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
    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;
    localparam ST_NORM = 2'd2;
    localparam ST_DONE = 2'd3;

    reg [1:0] state;
    reg [1:0] stage;
    reg [3:0] butterfly_idx;
    reg [3:0] norm_idx;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [3:0] p_addr;
    wire [3:0] q_addr;
    wire [3:0] tw_addr;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] y_p_real;
    wire signed [OUT_W-1:0] y_p_imag;
    wire signed [OUT_W-1:0] y_q_real;
    wire signed [OUT_W-1:0] y_q_imag;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mem_real[gi];
            assign data_imag_out[gi] = mem_imag[gi];
        end
    endgenerate

    assign done = done_r;

    fft16_addr_gen u_addr_gen (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .p_addr(p_addr),
        .q_addr(q_addr),
        .tw_addr(tw_addr)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .addr(tw_addr),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    fft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
        .mode(mode),
        .a_real(mem_real[p_addr]),
        .a_imag(mem_imag[p_addr]),
        .b_real(mem_real[q_addr]),
        .b_imag(mem_imag[q_addr]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y_a_real(y_p_real),
        .y_a_imag(y_p_imag),
        .y_b_real(y_q_real),
        .y_b_imag(y_q_imag)
    );

    integer i;
    wire [3:0] bitrev_idx [0:N-1];

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : BITREV_GEN
            fft16_bit_reverse u_bit_reverse (
                .in_idx(gi[3:0]),
                .out_idx(bitrev_idx[gi])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            stage <= 2'd0;
            butterfly_idx <= 4'd0;
            norm_idx <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        butterfly_idx <= 4'd0;
                        norm_idx <= 4'd0;
                        state <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    mem_real[p_addr] <= y_p_real;
                    mem_imag[p_addr] <= y_p_imag;
                    mem_real[q_addr] <= y_q_real;
                    mem_imag[q_addr] <= y_q_imag;

                    if (butterfly_idx == 4'd7) begin
                        butterfly_idx <= 4'd0;
                        if (stage == 2'd3) begin
                            if (mode) begin
                                norm_idx <= 4'd0;
                                state <= ST_NORM;
                            end else begin
                                done_r <= 1'b1;
                                state <= ST_DONE;
                            end
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 4'd1;
                    end
                end

                ST_NORM: begin
                    mem_real[norm_idx] <= mem_real[norm_idx] >>> GAIN_W;
                    mem_imag[norm_idx] <= mem_imag[norm_idx] >>> GAIN_W;
                    if (norm_idx == 4'd15) begin
                        done_r <= 1'b1;
                        state <= ST_DONE;
                    end else begin
                        norm_idx <= norm_idx + 4'd1;
                    end
                end

                ST_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bitrev_idx[i]] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bitrev_idx[i]] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 2'd0;
                        butterfly_idx <= 4'd0;
                        norm_idx <= 4'd0;
                        state <= ST_RUN;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done_r <= 1'b0;
                end
            endcase
        end
    end

endmodule