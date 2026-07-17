`timescale 1ns/1ps

module fp_bandpass_fir #(
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
  reg [31:0] data_q;

  wire [TAP_CNT*32-1:0] sample_bus;
  wire [TAP_CNT*32-1:0] coeff_bus;
  wire [31:0] fir_result;

  integer i;

  genvar g;
  generate
    for (g = 0; g < TAP_CNT; g = g + 1) begin : PACK_SAMPLES
      assign sample_bus[g*32 +: 32] = sample_hist[g];
    end
  endgenerate

  fp_bpf_coeff_rom #(
      .TAP_CNT(TAP_CNT)
  ) coeffs (
      .coeff_bus(coeff_bus)
  );

  fp_bpf_mac #(
      .TAP_CNT(TAP_CNT)
  ) mac (
      .sample_bus(sample_bus),
      .coeff_bus(coeff_bus),
      .result(fir_result)
  );

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_hist[i] <= 32'h00000000;
      valid_q <= 1'b0;
      data_q <= 32'h00000000;
    end else begin
      valid_q <= valid_in;
      if (valid_in) begin
        for (i = TAP_CNT-1; i > 0; i = i - 1)
          sample_hist[i] <= sample_hist[i-1];
        sample_hist[0] <= data_in;
        data_q <= fir_result;
      end
    end
  end

  assign valid_out = valid_q;
  assign data_out = data_q;

endmodule