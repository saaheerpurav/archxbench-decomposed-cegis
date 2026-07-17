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

  reg [31:0] sample_history [0:TAP_CNT-1];
  reg valid_q;
  integer i;

  wire [31:0] fir_result;

  fp_fir_sample_bank #(
      .TAP_CNT(TAP_CNT)
  ) u_fir_sample_bank (
      .samples_flat(sample_history),
      .sample_vector()
  );

  fp_bandpass_fir_mac #(
      .TAP_CNT(TAP_CNT)
  ) u_fir_mac (
      .samples(sample_history),
      .result(fir_result)
  );

  fp_valid_delay #(
      .LATENCY(0)
  ) u_valid_delay (
      .valid_i(valid_q),
      .valid_o(valid_out)
  );

  fp_output_select u_output_select (
      .valid_i(valid_q),
      .data_i(fir_result),
      .data_o(data_out)
  );

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_history[i] <= 32'h00000000;
      valid_q <= 1'b0;
    end else begin
      valid_q <= valid_in;
      if (valid_in) begin
        for (i = TAP_CNT-1; i > 0; i = i - 1)
          sample_history[i] <= sample_history[i-1];
        sample_history[0] <= data_in;
      end
    end
  end

endmodule