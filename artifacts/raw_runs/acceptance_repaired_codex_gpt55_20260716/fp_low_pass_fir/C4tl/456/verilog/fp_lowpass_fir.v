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

  reg [31:0] sample_hist [0:TAP_CNT-2];
  reg valid_q;
  reg [31:0] data_q;

  wire [TAP_CNT*32-1:0] coeff_bus;
  wire [TAP_CNT*32-1:0] sample_bus;
  wire [31:0] fir_result;

  genvar gi;
  generate
    for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : PACK_SAMPLES
      if (gi == 0) begin : PACK_CURRENT
        assign sample_bus[gi*32 +: 32] = data_in;
      end else begin : PACK_HISTORY
        assign sample_bus[gi*32 +: 32] = sample_hist[gi-1];
      end
    end
  endgenerate

  fp_fir_coeff_bank #(
    .TAP_CNT(TAP_CNT)
  ) coeffs (
    .coeff_bus(coeff_bus)
  );

  fp_fir_dot_product #(
    .TAP_CNT(TAP_CNT)
  ) dot_product (
    .sample_bus(sample_bus),
    .coeff_bus(coeff_bus),
    .result(fir_result)
  );

  assign valid_out = valid_q;
  assign data_out = data_q;

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      data_q <= 32'h00000000;
      for (i = 0; i < TAP_CNT-1; i = i + 1)
        sample_hist[i] <= 32'h00000000;
    end else begin
      valid_q <= valid_in;
      if (valid_in) begin
        data_q <= fir_result;
        if (TAP_CNT > 1) begin
          for (i = TAP_CNT-2; i > 0; i = i - 1)
            sample_hist[i] <= sample_hist[i-1];
          sample_hist[0] <= data_in;
        end
      end else begin
        data_q <= 32'h00000000;
      end
    end
  end

endmodule