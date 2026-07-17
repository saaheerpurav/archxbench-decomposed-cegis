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
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [2:0] stage;
    reg [4:0] group_base;
    reg [4:0] j_idx;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [4:0] m_size;
    wire [4:0] half_size;
    wire [4:0] tw_stride;
    wire [4:0] p_idx;
    wire [4:0] q_idx;
    wire [3:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    integer i;

    assign m_size    = 5'd1 << (stage + 1);
    assign half_size = 5'd1 << stage;
    assign tw_stride = N >> (stage + 1);
    assign p_idx     = group_base + j_idx;
    assign q_idx     = group_base + j_idx + half_size;
    assign tw_idx    = j_idx * tw_stride;

    assign done = (state == S_DONE);

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
        .mode(mode),
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

    function [3:0] bit_reverse4;
        input [3:0] x;
        begin
            bit_reverse4 = {x[0], x[1], x[2], x[3]};
        end
    endfunction

    generate
        genvar gi;
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUTPUTS
            assign data_real_out[gi] = mode ? (mem_real[gi] >>> LOGN) : mem_real[gi];
            assign data_imag_out[gi] = mode ? (mem_imag[gi] >>> LOGN) : mem_imag[gi];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            stage      <= 3'd0;
            group_base <= 5'd0;
            j_idx      <= 5'd0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage      <= 3'd0;
                        group_base <= 5'd0;
                        j_idx      <= 5'd0;
                        state      <= S_RUN;
                    end
                end

                S_RUN: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (j_idx == half_size - 1) begin
                        j_idx <= 5'd0;
                        if (group_base + m_size >= N) begin
                            group_base <= 5'd0;
                            if (stage == LOGN - 1) begin
                                state <= S_DONE;
                            end else begin
                                stage <= stage + 1'b1;
                            end
                        end else begin
                            group_base <= group_base + m_size;
                        end
                    end else begin
                        j_idx <= j_idx + 1'b1;
                    end
                end

                S_DONE: begin
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            mem_real[bit_reverse4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            mem_imag[bit_reverse4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage      <= 3'd0;
                        group_base <= 5'd0;
                        j_idx      <= 5'd0;
                        state      <= S_RUN;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule