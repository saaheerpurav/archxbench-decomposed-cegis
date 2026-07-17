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

  reg [31:0] hist [0:TAP_CNT-2];
  reg [31:0] data_out_r;
  reg valid_out_r;
  integer i;

  wire [32*TAP_CNT-1:0] sample_vec;
  wire [31:0] fir_y;

  assign sample_vec[31:0] = data_in;

  genvar g;
  generate
    for (g = 1; g < TAP_CNT; g = g + 1) begin : PACK_HISTORY
      assign sample_vec[g*32 +: 32] = hist[g-1];
    end
  endgenerate

  fp_fir_mac_comb #(.TAP_CNT(TAP_CNT)) u_mac (
    .samples(sample_vec),
    .result(fir_y)
  );

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT-1; i = i + 1)
        hist[i] <= 32'h00000000;
      data_out_r <= 32'h00000000;
      valid_out_r <= 1'b0;
    end else begin
      valid_out_r <= valid_in;
      if (valid_in) begin
        data_out_r <= fir_y;
        for (i = TAP_CNT-2; i > 0; i = i - 1)
          hist[i] <= hist[i-1];
        if (TAP_CNT > 1)
          hist[0] <= data_in;
      end
    end
  end

  assign valid_out = valid_out_r;
  assign data_out = data_out_r;

endmodule