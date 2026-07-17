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

  reg [TAP_CNT*32-1:0] sample_vec;
  reg valid_q;

  wire [TAP_CNT*32-1:0] coeff_vec;
  wire [31:0] fir_y;

  fp_hpf_coeff_rom #(.TAP_CNT(TAP_CNT)) u_coeff_rom (
    .coeffs(coeff_vec)
  );

  fp_hpf_fir_dot #(.TAP_CNT(TAP_CNT)) u_fir_dot (
    .samples(sample_vec),
    .coeffs(coeff_vec),
    .result(fir_y)
  );

  assign valid_out = valid_q;
  assign data_out = fir_y;

  always @(posedge clk) begin
    if (rst) begin
      sample_vec <= {TAP_CNT*32{1'b0}};
      valid_q <= 1'b0;
    end else begin
      valid_q <= valid_in;
      if (valid_in) begin
        sample_vec <= {sample_vec[(TAP_CNT-1)*32-1:0], data_in};
      end
    end
  end

endmodule