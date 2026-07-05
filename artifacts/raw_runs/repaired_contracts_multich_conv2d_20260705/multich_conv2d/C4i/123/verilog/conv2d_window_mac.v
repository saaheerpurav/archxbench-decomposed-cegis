`timescale 1ns/1ps

module conv2d_window_mac #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter BIAS_W = 16,
    parameter ACC_W = 40,
    parameter OC_W = 3,
    parameter ROW_W = 6,
    parameter COL_W = 6
)(
    input [CIN*H*W*DATA_W-1:0] image_flat,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [COUT*BIAS_W-1:0] bias,
    input [OC_W-1:0] out_ch,
    input [ROW_W-1:0] out_row,
    input [COL_W-1:0] out_col,
    output reg signed [ACC_W-1:0] sum
);

    integer c;
    integer kr;
    integer kc;
    integer img_idx;
    integer ker_idx;

    reg [DATA_W-1:0] pix;
    reg [DATA_W-1:0] weight;
    reg [2*DATA_W-1:0] product;
    reg signed [BIAS_W-1:0] bias_s;

    always @* begin
        bias_s = bias[out_ch*BIAS_W +: BIAS_W];
        sum = {{(ACC_W-BIAS_W){bias_s[BIAS_W-1]}}, bias_s};

        for (c = 0; c < CIN; c = c + 1) begin
            for (kr = 0; kr < K; kr = kr + 1) begin
                for (kc = 0; kc < K; kc = kc + 1) begin
                    img_idx = (c * H * W) + ((out_row + kr) * W) + (out_col + kc);
                    ker_idx = (((out_ch * CIN + c) * K + kr) * K + kc);

                    pix = image_flat[img_idx*DATA_W +: DATA_W];
                    weight = kernel[ker_idx*DATA_W +: DATA_W];
                    product = pix * weight;

                    sum = sum + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
                end
            end
        end
    end

endmodule