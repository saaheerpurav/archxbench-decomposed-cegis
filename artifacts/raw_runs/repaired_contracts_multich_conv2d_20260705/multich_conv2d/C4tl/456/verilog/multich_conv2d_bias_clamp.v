`timescale 1ns/1ps

module multich_conv2d_bias_clamp #(
    parameter COUT = 8,
    parameter BIAS_W = 16,
    parameter ACC_W = 32,
    parameter OUT_W = 16
)(
    input  [ACC_W-1:0] sum_in,
    input  [COUT*BIAS_W-1:0] bias,
    input  [31:0] out_ch,
    output reg [OUT_W-1:0] pixel_out
);
    localparam MAX_AB_W = (ACC_W > BIAS_W) ? ACC_W : BIAS_W;
    localparam MAX_IN_W = (MAX_AB_W > OUT_W) ? MAX_AB_W : OUT_W;
    localparam CALC_W   = MAX_IN_W + 1;

    reg [BIAS_W-1:0] bias_val;
    reg [CALC_W-1:0] sum_ext;
    reg [CALC_W-1:0] bias_ext;
    reg [CALC_W-1:0] biased_sum;
    reg [CALC_W-1:0] max_out;

    always @* begin
        bias_val = {BIAS_W{1'b0}};
        if (out_ch < COUT) begin
            bias_val = bias[out_ch*BIAS_W +: BIAS_W];
        end

        sum_ext    = {{(CALC_W-ACC_W){1'b0}}, sum_in};
        bias_ext   = {{(CALC_W-BIAS_W){1'b0}}, bias_val};
        biased_sum = sum_ext + bias_ext;
        max_out    = {{(CALC_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

        if (biased_sum > max_out) begin
            pixel_out = {OUT_W{1'b1}};
        end else begin
            pixel_out = biased_sum[OUT_W-1:0];
        end
    end
endmodule