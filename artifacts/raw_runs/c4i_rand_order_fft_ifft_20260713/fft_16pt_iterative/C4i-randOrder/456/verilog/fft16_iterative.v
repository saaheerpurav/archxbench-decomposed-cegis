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
    output reg signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output reg signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1],
    output reg done
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam LOGN  = 4;

    localparam ST_IDLE    = 3'd0;
    localparam ST_LOAD    = 3'd1;
    localparam ST_COMPUTE = 3'd2;
    localparam ST_STORE   = 3'd3;
    localparam ST_DONE    = 3'd4;

    reg [2:0] state;

    reg signed [OUT_W-1:0] mem_real [0:N-1];
    reg signed [OUT_W-1:0] mem_imag [0:N-1];

    reg [LOGN-1:0] load_idx;
    wire [LOGN-1:0] load_rev_idx;

    reg [2:0] stage;
    reg [3:0] butterfly_idx;

    reg [LOGN-1:0] p_idx;
    reg [LOGN-1:0] q_idx;
    reg [LOGN-1:0] tw_idx;

    reg [LOGN-1:0] store_idx;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] bf_p_real;
    wire signed [OUT_W-1:0] bf_p_imag;
    wire signed [OUT_W-1:0] bf_q_real;
    wire signed [OUT_W-1:0] bf_q_imag;

    wire signed [OUT_W-1:0] scaled_real;
    wire signed [OUT_W-1:0] scaled_imag;

    integer i;

    fft16_bit_reverse #(
        .LOGN(LOGN)
    ) u_bit_reverse (
        .idx(load_idx),
        .rev_idx(load_rev_idx)
    );

    fft16_twiddle_rom #(
        .COEFF_W(COEFF_W)
    ) u_twiddle_rom (
        .addr(tw_idx),
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

    fft16_ifft_scale #(
        .DATA_W(OUT_W),
        .LOGN(LOGN)
    ) u_ifft_scale (
        .mode(mode),
        .in_real(mem_real[store_idx]),
        .in_imag(mem_imag[store_idx]),
        .out_real(scaled_real),
        .out_imag(scaled_imag)
    );

    always @* begin
        case (stage)
            3'd0: begin
                p_idx  = {butterfly_idx[2:0], 1'b0};
                q_idx  = {butterfly_idx[2:0], 1'b0} + 4'd1;
                tw_idx = 4'd0;
            end
            3'd1: begin
                p_idx  = {butterfly_idx[2:1], 2'b00} + {3'b000, butterfly_idx[0]};
                q_idx  = ({butterfly_idx[2:1], 2'b00} + {3'b000, butterfly_idx[0]}) + 4'd2;
                tw_idx = {butterfly_idx[0], 3'b000};
            end
            3'd2: begin
                p_idx  = {butterfly_idx[2], 3'b000} + {2'b00, butterfly_idx[1:0]};
                q_idx  = ({butterfly_idx[2], 3'b000} + {2'b00, butterfly_idx[1:0]}) + 4'd4;
                tw_idx = {butterfly_idx[1:0], 2'b00};
            end
            default: begin
                p_idx  = {1'b0, butterfly_idx[2:0]};
                q_idx  = {1'b0, butterfly_idx[2:0]} + 4'd8;
                tw_idx = {butterfly_idx[2:0], 1'b0};
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            done <= 1'b0;
            load_idx <= 0;
            stage <= 0;
            butterfly_idx <= 0;
            store_idx <= 0;
            for (i = 0; i < N; i = i + 1) begin
                mem_real[i] <= {OUT_W{1'b0}};
                mem_imag[i] <= {OUT_W{1'b0}};
                data_real_out[i] <= {OUT_W{1'b0}};
                data_imag_out[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        load_idx <= 0;
                        state <= ST_LOAD;
                    end
                end

                ST_LOAD: begin
                    mem_real[load_rev_idx] <= {{GAIN_W{data_real_in[load_idx][DATA_W-1]}}, data_real_in[load_idx]};
                    mem_imag[load_rev_idx] <= {{GAIN_W{data_imag_in[load_idx][DATA_W-1]}}, data_imag_in[load_idx]};

                    if (load_idx == N-1) begin
                        stage <= 0;
                        butterfly_idx <= 0;
                        state <= ST_COMPUTE;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                ST_COMPUTE: begin
                    mem_real[p_idx] <= bf_p_real;
                    mem_imag[p_idx] <= bf_p_imag;
                    mem_real[q_idx] <= bf_q_real;
                    mem_imag[q_idx] <= bf_q_imag;

                    if (butterfly_idx == 4'd7) begin
                        butterfly_idx <= 0;
                        if (stage == 3'd3) begin
                            store_idx <= 0;
                            state <= ST_STORE;
                        end else begin
                            stage <= stage + 1'b1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 1'b1;
                    end
                end

                ST_STORE: begin
                    data_real_out[store_idx] <= scaled_real;
                    data_imag_out[store_idx] <= scaled_imag;

                    if (store_idx == N-1) begin
                        done <= 1'b1;
                        state <= ST_DONE;
                    end else begin
                        store_idx <= store_idx + 1'b1;
                    end
                end

                ST_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        done <= 1'b0;
                        load_idx <= 0;
                        state <= ST_LOAD;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule