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

  reg [31:0] sample_hist [0:TAP_CNT-1];
  reg valid_q;

  integer i;

  wire [31:0] coeff [0:TAP_CNT-1];
  wire [31:0] prod  [0:TAP_CNT-1];
  wire [31:0] sum   [0:TAP_CNT-1];

  assign valid_out = valid_q;
  assign data_out = sum[TAP_CNT-1];

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_hist[i] <= 32'h00000000;
    end else begin
      valid_q <= valid_in;
      if (valid_in) begin
        sample_hist[0] <= data_in;
        for (i = 1; i < TAP_CNT; i = i + 1)
          sample_hist[i] <= sample_hist[i-1];
      end
    end
  end

  genvar g;
  generate
    for (g = 0; g < TAP_CNT; g = g + 1) begin : FIR_TAPS
      fp_fir_coeff_rom coeff_rom_i (
        .tap_idx(g[7:0]),
        .coeff(coeff[g])
      );

      fp32_mul mul_i (
        .a(sample_hist[g]),
        .b(coeff[g]),
        .y(prod[g])
      );

      if (g == 0) begin : FIRST_SUM
        assign sum[g] = prod[g];
      end else begin : NEXT_SUM
        fp32_add add_i (
          .a(sum[g-1]),
          .b(prod[g]),
          .y(sum[g])
        );
      end
    end
  endgenerate

endmodule