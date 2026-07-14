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

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOG_N = clog2(N);
    localparam ST_IDLE = 2'd0;
    localparam ST_LOAD = 2'd1;
    localparam ST_RUN  = 2'd2;
    localparam ST_DONE = 2'd3;

    reg [1:0] state;
    reg [LOG_N-1:0] load_idx;
    reg [LOG_N-1:0] stage;
    reg [LOG_N-1:0] group_base;
    reg [LOG_N-1:0] j_idx;
    reg done_r;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    wire [LOG_N-1:0] load_addr;
    wire [LOG_N-1:0] half_size;
    wire [LOG_N:0] m_size;
    wire [LOG_N-1:0] p_addr;
    wire [LOG_N-1:0] q_addr;
    wire [LOG_N-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_OUTPUTS
            fft16_ifft_scale #(
                .IN_W(OUT_W),
                .OUT_W(OUT_W),
                .SHIFT(GAIN_W)
            ) scale_real (
                .in_val(mem_real[gi]),
                .do_scale(mode),
                .out_val(data_real_out[gi])
            );

            fft16_ifft_scale #(
                .IN_W(OUT_W),
                .OUT_W(OUT_W),
                .SHIFT(GAIN_W)
            ) scale_imag (
                .in_val(mem_imag[gi]),
                .do_scale(mode),
                .out_val(data_imag_out[gi])
            );
        end
    endgenerate

    assign done = done_r;

    assign half_size = {{(LOG_N-1){1'b0}}, 1'b1} << stage;
    assign m_size = {{LOG_N{1'b0}}, 1'b1} << (stage + 1'b1);

    fft16_bit_reverse #(
        .N(N),
        .ADDR_W(LOG_N)
    ) load_bit_reverse (
        .addr_in(load_idx),
        .addr_out(load_addr)
    );

    fft16_pair_address #(
        .N(N),
        .ADDR_W(LOG_N)
    ) pair_address (
        .stage(stage),
        .group_base(group_base),
        .j_idx(j_idx),
        .p_addr(p_addr),
        .q_addr(q_addr),
        .tw_idx(tw_idx)
    );

    fft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W),
        .ADDR_W(LOG_N)
    ) twiddle_rom (
        .tw_idx(tw_idx),
        .mode(mode),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin)
    );

    fft16_butterfly_q15 #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) butterfly (
        .a_real(mem_real[p_addr]),
        .a_imag(mem_imag[p_addr]),
        .b_real(mem_real[q_addr]),
        .b_imag(mem_imag[q_addr]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y0_real(bf_p_real),
        .y0_imag(bf_p_imag),
        .y1_real(bf_q_real),
        .y1_imag(bf_q_imag)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            load_idx <= {LOG_N{1'b0}};
            stage <= {LOG_N{1'b0}};
            group_base <= {LOG_N{1'b0}};
            j_idx <= {LOG_N{1'b0}};
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
                        load_idx <= {LOG_N{1'b0}};
                        state <= ST_LOAD;
                    end
                end

                ST_LOAD: begin
                    mem_real[load_addr] <= {{GAIN_W{data_real_in[load_idx][DATA_W-1]}}, data_real_in[load_idx]};
                    mem_imag[load_addr] <= {{GAIN_W{data_imag_in[load_idx][DATA_W-1]}}, data_imag_in[load_idx]};

                    if (load_idx == N-1) begin
                        stage <= {LOG_N{1'b0}};
                        group_base <= {LOG_N{1'b0}};
                        j_idx <= {LOG_N{1'b0}};
                        state <= ST_RUN;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                ST_RUN: begin
                    mem_real[p_addr] <= bf_p_real;
                    mem_imag[p_addr] <= bf_p_imag;
                    mem_real[q_addr] <= bf_q_real;
                    mem_imag[q_addr] <= bf_q_imag;

                    if (j_idx == half_size - 1'b1) begin
                        j_idx <= {LOG_N{1'b0}};
                        if (group_base + m_size[LOG_N-1:0] >= N[LOG_N-1:0]) begin
                            group_base <= {LOG_N{1'b0}};
                            if (stage == LOG_N - 1) begin
                                state <= ST_DONE;
                                done_r <= 1'b1;
                            end else begin
                                stage <= stage + 1'b1;
                            end
                        end else begin
                            group_base <= group_base + m_size[LOG_N-1:0];
                        end
                    end else begin
                        j_idx <= j_idx + 1'b1;
                    end
                end

                ST_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        load_idx <= {LOG_N{1'b0}};
                        state <= ST_LOAD;
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