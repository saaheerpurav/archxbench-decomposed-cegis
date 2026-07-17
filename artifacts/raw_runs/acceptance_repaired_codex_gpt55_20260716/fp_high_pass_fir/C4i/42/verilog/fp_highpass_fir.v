`timescale 1ns/1ps

module fp_highpass_fir #(
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
  reg [31:0] data_out_r;
  reg valid_out_r;

  wire [31:0] sample_word [0:TAP_CNT-1];
  wire [31:0] coeff_word [0:TAP_CNT-1];
  wire [31:0] product_word [0:TAP_CNT-1];
  wire [31:0] sum_word [0:TAP_CNT-1];

  integer i;

  assign valid_out = valid_out_r;
  assign data_out = data_out_r;

  genvar g;
  generate
    for (g = 0; g < TAP_CNT; g = g + 1) begin : GEN_FIR
      fp_fir_sample_select #(.INDEX(g)) u_sample_select (
        .new_sample(data_in),
        .hist_sample((g == 0) ? 32'h00000000 : sample_hist[g-1]),
        .sample_out(sample_word[g])
      );

      fp_highpass_coeff_rom #(.INDEX(g)) u_coeff_rom (
        .coeff(coeff_word[g])
      );

      fp_mul_comb u_mul (
        .a(sample_word[g]),
        .b(coeff_word[g]),
        .y(product_word[g])
      );

      if (g == 0) begin : GEN_SUM0
        assign sum_word[g] = product_word[g];
      end else begin : GEN_SUMN
        fp_add_comb u_add (
          .a(sum_word[g-1]),
          .b(product_word[g]),
          .y(sum_word[g])
        );
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_hist[i] <= 32'h00000000;
      data_out_r <= 32'h00000000;
      valid_out_r <= 1'b0;
    end else begin
      valid_out_r <= valid_in;
      if (valid_in) begin
        sample_hist[0] <= data_in;
        for (i = 1; i < TAP_CNT; i = i + 1)
          sample_hist[i] <= sample_hist[i-1];
        data_out_r <= sum_word[TAP_CNT-1];
      end
    end
  end

endmodule