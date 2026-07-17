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
    localparam STAGES = 4;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [2:0] stage;
    reg [3:0] butterfly_idx;
    reg done_r;

    reg signed [OUT_W-1:0] xr [0:N-1];
    reg signed [OUT_W-1:0] xi [0:N-1];

    wire [3:0] p_addr;
    wire [3:0] q_addr;
    wire [3:0] tw_addr;

    wire signed [COEFF_W-1:0] tw_cos;
    wire signed [COEFF_W-1:0] tw_sin;

    wire signed [OUT_W-1:0] y_p_real;
    wire signed [OUT_W-1:0] y_p_imag;
    wire signed [OUT_W-1:0] y_q_real;
    wire signed [OUT_W-1:0] y_q_imag;

    integer i;

    assign done = done_r;

    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
            assign data_real_out[gi] = mode ? (xr[gi] >>> GAIN_W) : xr[gi];
            assign data_imag_out[gi] = mode ? (xi[gi] >>> GAIN_W) : xi[gi];
        end
    endgenerate

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
        .a_real(xr[p_addr]),
        .a_imag(xi[p_addr]),
        .b_real(xr[q_addr]),
        .b_imag(xi[q_addr]),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y_p_real(y_p_real),
        .y_p_imag(y_p_imag),
        .y_q_real(y_q_real),
        .y_q_imag(y_q_imag)
    );

    function [3:0] bit_reverse4;
        input [3:0] value;
        begin
            bit_reverse4 = {value[0], value[1], value[2], value[3]};
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            stage <= 3'd0;
            butterfly_idx <= 4'd0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                xr[i] <= {OUT_W{1'b0}};
                xi[i] <= {OUT_W{1'b0}};
            end
        end else begin
            case (state)
                S_IDLE: begin
                    done_r <= 1'b0;
                    if (start) begin
                        for (i = 0; i < N; i = i + 1) begin
                            xr[bit_reverse4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            xi[bit_reverse4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 3'd0;
                        butterfly_idx <= 4'd0;
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    xr[p_addr] <= y_p_real;
                    xi[p_addr] <= y_p_imag;
                    xr[q_addr] <= y_q_real;
                    xi[q_addr] <= y_q_imag;

                    if (butterfly_idx == 4'd7) begin
                        butterfly_idx <= 4'd0;
                        if (stage == STAGES-1) begin
                            done_r <= 1'b1;
                            state <= S_DONE;
                        end else begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        butterfly_idx <= butterfly_idx + 4'd1;
                    end
                end

                S_DONE: begin
                    done_r <= 1'b1;
                    if (start) begin
                        done_r <= 1'b0;
                        for (i = 0; i < N; i = i + 1) begin
                            xr[bit_reverse4(i[3:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
                            xi[bit_reverse4(i[3:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
                        end
                        stage <= 3'd0;
                        butterfly_idx <= 4'd0;
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