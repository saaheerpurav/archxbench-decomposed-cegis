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

  localparam LATENCY = TAP_CNT - 1;

  reg [31:0] sample_delay [0:TAP_CNT-1];
  reg [LATENCY:0] valid_pipe;
  integer i;

  wire [TAP_CNT*32-1:0] packed_samples;
  wire [31:0] fir_comb_out;

  genvar gi;
  generate
    for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : PACK_SAMPLES
      assign packed_samples[gi*32 +: 32] = sample_delay[gi];
    end
  endgenerate

  hp_fir_mac_comb #(
    .TAP_CNT(TAP_CNT)
  ) u_mac (
    .samples_flat(packed_samples),
    .result(fir_comb_out)
  );

  reg [31:0] data_out_reg;
  assign data_out = data_out_reg;
  assign valid_out = valid_pipe[LATENCY];

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_delay[i] <= 32'h00000000;
      valid_pipe <= {LATENCY+1{1'b0}};
      data_out_reg <= 32'h00000000;
    end else begin
      valid_pipe <= {valid_pipe[LATENCY-1:0], valid_in};

      if (valid_in) begin
        sample_delay[0] <= data_in;
        for (i = 1; i < TAP_CNT; i = i + 1)
          sample_delay[i] <= sample_delay[i-1];
      end

      data_out_reg <= fir_comb_out;
    end
  end

endmodule