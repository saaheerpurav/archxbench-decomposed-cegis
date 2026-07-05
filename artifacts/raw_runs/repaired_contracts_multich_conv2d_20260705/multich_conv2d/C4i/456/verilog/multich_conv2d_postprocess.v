`timescale 1ns/1ps

module multich_conv2d_postprocess #(
    parameter COUT = 8,
    parameter BIAS_W = 16,
    parameter OUT_W = 16,
    parameter MAC_W = 24,
    parameter COUT_W = 4
)(
    input [MAC_W-1:0] mac_in,
    input [COUT*BIAS_W-1:0] bias,
    input [COUT_W-1:0] out_ch,
    output reg [OUT_W-1:0] pixel_out
);

  localparam SUM_W = (MAC_W > BIAS_W ? MAC_W : BIAS_W) + 1;
  localparam COPY_W = (OUT_W < SUM_W) ? OUT_W : SUM_W;

  reg [BIAS_W-1:0] bias_value;
  reg [SUM_W-1:0] biased_value;
  reg overflow;
  integer i;

  always @* begin
    bias_value = bias[out_ch*BIAS_W +: BIAS_W];
    biased_value = {{(SUM_W-MAC_W){1'b0}}, mac_in}
                 + {{(SUM_W-BIAS_W){1'b0}}, bias_value};

    overflow = 1'b0;
    for (i = OUT_W; i < SUM_W; i = i + 1) begin
      if (biased_value[i])
        overflow = 1'b1;
    end

    if (overflow) begin
      pixel_out = {OUT_W{1'b1}};
    end else begin
      pixel_out = {OUT_W{1'b0}};
      pixel_out[COPY_W-1:0] = biased_value[COPY_W-1:0];
    end
  end

endmodule