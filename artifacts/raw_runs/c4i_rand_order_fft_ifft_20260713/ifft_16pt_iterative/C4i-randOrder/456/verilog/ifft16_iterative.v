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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOG_N = $clog2(N);
    localparam TOTAL_BFLY = (N/2) * LOG_N;

    localparam S_IDLE    = 3'd0;
    localparam S_LOAD    = 3'd1;
    localparam S_COMPUTE = 3'd2;
    localparam S_SCALE   = 3'd3;
    localparam S_DONE    = 3'd4;

    reg [2:0] state;
    reg [LOG_N-1:0] stage;
    reg [$clog2(N/2)-1:0] butterfly_idx;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];
    reg signed [OUT_W-1:0] out_real_r [0:N-1];
    reg signed [OUT_W-1:0] out_imag_r [0:N-1];
    reg done_r;

    wire [LOG_N-1:0] p_idx;
    wire [LOG_N-1:0] q_idx;
    wire [LOG_N-1:0] tw_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    integer i;

    assign done = done_r;

    generate
        genvar gi;
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = out_real_r[gi];
            assign data_imag_out[gi] = out_imag_r[gi];
        end
    endgenerate

    ifft16_addr_gen #(
        .N(N)
    ) u_addr_gen (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .p_idx(p_idx),
        .q_idx(q_idx),
        .tw_idx(tw_idx)
    );

    ifft16_twiddle_rom #(
        .N(N),
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .idx(tw_idx),
        .cos_q15(tw_cos),
        .sin_q15(tw_sin)
    );

    ifft16_butterfly #(
        .DATA_W(OUT_W),
        .COEFF_W(COEFF_W)
    ) u_butterfly (
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

    function integer bit_reverse;
        input integer value;
        integer b;
        begin
            bit_reverse = 0;
            for (b = 0; b < LOG_N; b = b + 1)
                bit_reverse = (bit_reverse << 1) | ((value >> b) & 1);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= {LOG_N{1'b0}};
            butterfly_idx <= {($clog2(N/2)){1'b0}};
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                out_real_r[i] <= {OUT_W{1'b0}};
                out_imag_r[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    done_r <= 1'b0;
                    for (i = 0; i < N; i = i + 1) begin
                        mem_real[bit_reverse(i)] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                        mem_imag[bit_reverse(i)] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                    end
                    stage <= {LOG_N{1'b0}};
                    butterfly_idx <= {($clog2(N/2)){1'b0}};
                    state <= S_COMPUTE;
                end

                S_COMPUTE: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (stage == LOG_N-1 && butterfly_idx == (N/2)-1) begin
                        state <= S_SCALE;
                    end else if (butterfly_idx == (N/2)-1) begin
                        butterfly_idx <= {($clog2(N/2)){1'b0}};
                        stage <= stage + 1'b1;
                    end else begin
                        butterfly_idx <= butterfly_idx + 1'b1;
                    end
                end

                S_SCALE: begin
                    for (i = 0; i < N; i = i + 1) begin
                        out_real_r[i] <= mem_real[i] >>> LOG_N;
                        out_imag_r[i] <= mem_imag[i] >>> LOG_N;
                    end
                    done_r <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        state <= S_LOAD;
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