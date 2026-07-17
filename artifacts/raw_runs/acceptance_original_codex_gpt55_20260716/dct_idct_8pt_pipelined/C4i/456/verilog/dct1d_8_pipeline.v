`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

  localparam ACC_W = DATA_W + COEFF_W + 4;
  localparam FRAC_BITS = 14;

  reg signed [DATA_W-1:0] sample_buf [0:7];

  reg block_mode;
  reg emitting;
  reg [2:0] emit_index;

  wire signed [COEFF_W-1:0] c0;
  wire signed [COEFF_W-1:0] c1;
  wire signed [COEFF_W-1:0] c2;
  wire signed [COEFF_W-1:0] c3;
  wire signed [COEFF_W-1:0] c4;
  wire signed [COEFF_W-1:0] c5;
  wire signed [COEFF_W-1:0] c6;
  wire signed [COEFF_W-1:0] c7;

  wire signed [ACC_W-1:0] mac_sum;
  wire signed [ACC_W-1:0] scaled_sum;
  wire signed [OUT_W-1:0] clipped_sum;

  dct8_coeff_rom #(
    .COEFF_W(COEFF_W)
  ) u_coeff_rom (
    .mode(block_mode),
    .out_index(emit_index),
    .c0(c0),
    .c1(c1),
    .c2(c2),
    .c3(c3),
    .c4(c4),
    .c5(c5),
    .c6(c6),
    .c7(c7)
  );

  dct8_mac #(
    .DATA_W(DATA_W),
    .COEFF_W(COEFF_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .x0(sample_buf[0]),
    .x1(sample_buf[1]),
    .x2(sample_buf[2]),
    .x3(sample_buf[3]),
    .x4(sample_buf[4]),
    .x5(sample_buf[5]),
    .x6(sample_buf[6]),
    .x7(sample_buf[7]),
    .c0(c0),
    .c1(c1),
    .c2(c2),
    .c3(c3),
    .c4(c4),
    .c5(c5),
    .c6(c6),
    .c7(c7),
    .sum(mac_sum)
  );

  dct8_round_shift #(
    .IN_W(ACC_W),
    .FRAC_BITS(FRAC_BITS)
  ) u_round_shift (
    .in_value(mac_sum),
    .out_value(scaled_sum)
  );

  dct8_saturate #(
    .IN_W(ACC_W),
    .OUT_W(OUT_W)
  ) u_saturate (
    .in_value(scaled_sum),
    .out_value(clipped_sum)
  );

  assign coeff_out = clipped_sum;
  assign valid_out = emitting;
  assign index_out = emit_index;

  integer i;

  always @(posedge clk) begin
    if (rst) begin
      block_mode <= 1'b0;
      emitting <= 1'b0;
      emit_index <= 3'd0;
      for (i = 0; i < 8; i = i + 1) begin
        sample_buf[i] <= {DATA_W{1'b0}};
      end
    end else begin
      if (valid_in) begin
        sample_buf[index] <= sample_in;
        block_mode <= mode;
      end

      if (emitting) begin
        if (emit_index == 3'd7) begin
          emitting <= 1'b0;
          emit_index <= 3'd0;
        end else begin
          emit_index <= emit_index + 3'd1;
        end
      end else if (valid_in && index == 3'd7) begin
        emitting <= 1'b1;
        emit_index <= 3'd0;
      end
    end
  end

endmodule