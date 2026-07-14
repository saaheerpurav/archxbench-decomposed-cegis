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
  localparam LOGN  = 4;

  localparam S_IDLE = 2'd0;
  localparam S_RUN  = 2'd1;
  localparam S_DONE = 2'd2;

  reg [1:0] state;
  reg [LOGN-1:0] stage;
  reg [LOGN-1:0] butterfly_idx;
  reg mode_reg;

  reg signed [OUT_W-1:0] mem_real [0:N-1];
  reg signed [OUT_W-1:0] mem_imag [0:N-1];

  wire [LOGN-1:0] p_addr;
  wire [LOGN-1:0] q_addr;
  wire [LOGN-1:0] tw_addr;

  wire signed [COEFF_W-1:0] tw_cos;
  wire signed [COEFF_W-1:0] tw_sin;

  wire signed [OUT_W-1:0] y_p_real;
  wire signed [OUT_W-1:0] y_p_imag;
  wire signed [OUT_W-1:0] y_q_real;
  wire signed [OUT_W-1:0] y_q_imag;

  function [LOGN-1:0] bit_reverse;
    input [LOGN-1:0] value;
    integer b;
    begin
      for (b = 0; b < LOGN; b = b + 1)
        bit_reverse[b] = value[LOGN-1-b];
    end
  endfunction

  fft16_address_gen #(
    .N(N),
    .LOGN(LOGN)
  ) addr_gen (
    .stage(stage),
    .butterfly_idx(butterfly_idx),
    .p_addr(p_addr),
    .q_addr(q_addr),
    .tw_addr(tw_addr)
  );

  fft16_twiddle_rom #(
    .COEFF_W(COEFF_W)
  ) tw_rom (
    .addr(tw_addr),
    .cos_q15(tw_cos),
    .sin_q15(tw_sin)
  );

  fft16_butterfly #(
    .DATA_W(OUT_W),
    .COEFF_W(COEFF_W)
  ) butterfly (
    .mode(mode_reg),
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

  genvar gi;
  generate
    for (gi = 0; gi < N; gi = gi + 1) begin : OUT_ASSIGN
      fft16_output_scale #(
        .IN_W(OUT_W),
        .GAIN_W(GAIN_W)
      ) out_scale (
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
      stage <= {LOGN{1'b0}};
      butterfly_idx <= {LOGN{1'b0}};
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
            stage <= {LOGN{1'b0}};
            butterfly_idx <= {LOGN{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
              mem_real[bit_reverse(i[LOGN-1:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
              mem_imag[bit_reverse(i[LOGN-1:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
            end
            state <= S_RUN;
          end
        end

        S_RUN: begin
          mem_real[p_addr] <= y_p_real;
          mem_imag[p_addr] <= y_p_imag;
          mem_real[q_addr] <= y_q_real;
          mem_imag[q_addr] <= y_q_imag;

          if ((stage == LOGN-1) && (butterfly_idx == (N/2)-1)) begin
            state <= S_DONE;
          end else if (butterfly_idx == (N/2)-1) begin
            butterfly_idx <= {LOGN{1'b0}};
            stage <= stage + 1'b1;
          end else begin
            butterfly_idx <= butterfly_idx + 1'b1;
          end
        end

        S_DONE: begin
          if (start) begin
            mode_reg <= mode;
            stage <= {LOGN{1'b0}};
            butterfly_idx <= {LOGN{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
              mem_real[bit_reverse(i[LOGN-1:0])] <= {{GAIN_W{data_real_in[i][DATA_W-1]}}, data_real_in[i]};
              mem_imag[bit_reverse(i[LOGN-1:0])] <= {{GAIN_W{data_imag_in[i][DATA_W-1]}}, data_imag_in[i]};
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