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
  reg [31:0] data_out_r;
  reg valid_out_r;

  wire [TAP_CNT*32-1:0] hist_flat;
  wire [TAP_CNT*32-1:0] next_hist_flat;
  wire [31:0] fir_result;

  integer i;

  assign valid_out = valid_out_r;
  assign data_out = data_out_r;

  genvar gi;
  generate
    for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : FLATTEN_HISTORY
      assign hist_flat[gi*32 +: 32] = sample_hist[gi];
    end
  endgenerate

  fir_shift_next #(.TAP_CNT(TAP_CNT)) u_shift_next (
    .valid_in(valid_in),
    .data_in(data_in),
    .hist_in(hist_flat),
    .hist_out(next_hist_flat)
  );

  fp_fir_mac_101 #(.TAP_CNT(TAP_CNT)) u_fir_mac (
    .samples(next_hist_flat),
    .result(fir_result)
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
        data_out_r <= fir_result;
      end
    end
  end

endmodule