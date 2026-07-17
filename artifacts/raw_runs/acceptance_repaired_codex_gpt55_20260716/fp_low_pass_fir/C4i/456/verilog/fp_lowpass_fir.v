`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

  reg [31:0] x_hist [0:TAP_CNT-2];
  reg [31:0] out_r;
  reg valid_r;

  wire [31:0] sample_word [0:TAP_CNT-1];
  wire [31:0] coeff_word  [0:TAP_CNT-1];
  wire [31:0] prod_word   [0:TAP_CNT-1];
  wire [31:0] sum_word    [0:TAP_CNT-1];

  assign sample_word[0] = data_in;

  genvar i;
  generate
    for (i = 1; i < TAP_CNT; i = i + 1) begin : SAMPLE_MAP
      assign sample_word[i] = x_hist[i-1];
    end

    for (i = 0; i < TAP_CNT; i = i + 1) begin : TAP_CALC
      fp_lpf_coeff_rom u_coeff (
        .idx(i[7:0]),
        .coeff(coeff_word[i])
      );

      fp_lpf_tap_mult u_mult (
        .sample(sample_word[i]),
        .coeff(coeff_word[i]),
        .product(prod_word[i])
      );
    end

    assign sum_word[0] = prod_word[0];

    for (i = 1; i < TAP_CNT; i = i + 1) begin : SUM_CHAIN
      fp_lpf_accum_add u_add (
        .a(sum_word[i-1]),
        .b(prod_word[i]),
        .sum(sum_word[i])
      );
    end
  endgenerate

  integer k;
  always @(posedge clk) begin
    if (rst) begin
      valid_r <= 1'b0;
      out_r <= 32'h00000000;
      for (k = 0; k < TAP_CNT-1; k = k + 1)
        x_hist[k] <= 32'h00000000;
    end else begin
      valid_r <= valid_in;
      if (valid_in) begin
        out_r <= sum_word[TAP_CNT-1];
        for (k = TAP_CNT-2; k > 0; k = k - 1)
          x_hist[k] <= x_hist[k-1];
        x_hist[0] <= data_in;
      end
    end
  end

  assign valid_out = valid_r;
  assign data_out = out_r;

endmodule