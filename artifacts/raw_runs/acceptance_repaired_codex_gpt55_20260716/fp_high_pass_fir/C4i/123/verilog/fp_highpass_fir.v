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

  wire [32*TAP_CNT-1:0] sample_bus;
  wire [32*TAP_CNT-1:0] coeff_bus;
  wire [31:0] fir_sum;

  integer i;

  assign valid_out = valid_out_r;
  assign data_out = data_out_r;

  genvar gi;
  generate
    for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : PACK_SAMPLES
      assign sample_bus[32*gi +: 32] =
        (gi == 0) ? (valid_in ? data_in : 32'h00000000) : sample_hist[gi-1];
    end
  endgenerate

  fp_hpf_coeff_rom #(.TAP_CNT(TAP_CNT)) u_coeff_rom (
    .coeff_bus(coeff_bus)
  );

  fp_fir_dot_product #(.TAP_CNT(TAP_CNT)) u_dot_product (
    .sample_bus(sample_bus),
    .coeff_bus(coeff_bus),
    .result(fir_sum)
  );

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
        data_out_r <= fir_sum;
      end else begin
        data_out_r <= data_out_r;
      end
    end
  end

endmodule