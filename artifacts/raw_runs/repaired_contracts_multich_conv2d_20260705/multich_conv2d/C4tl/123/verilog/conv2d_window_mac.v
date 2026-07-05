`timescale 1ns/1ps

module conv2d_window_mac #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter ACC_W = 32
)(
    input [CIN*H*W*DATA_W-1:0] frame_flat,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [31:0] out_ch,
    input [31:0] out_row,
    input [31:0] out_col,
    output reg signed [ACC_W-1:0] sum
);

    integer c;
    integer kr;
    integer kc;
    integer pix_idx;
    integer ker_idx;

    reg [DATA_W-1:0] pix;
    reg [DATA_W-1:0] wt;
    reg [2*DATA_W-1:0] product;

    always @* begin
        sum = {ACC_W{1'b0}};

        for (c = 0; c < CIN; c = c + 1) begin
            for (kr = 0; kr < K; kr = kr + 1) begin
                for (kc = 0; kc < K; kc = kc + 1) begin
                    pix_idx = ((c * H + (out_row + kr)) * W + (out_col + kc));
                    ker_idx = (((out_ch * CIN + c) * K + kr) * K + kc);

                    pix = frame_flat[pix_idx*DATA_W +: DATA_W];
                    wt = kernel[ker_idx*DATA_W +: DATA_W];

                    product = pix * wt;
                    sum = sum + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
                end
            end
        end
    end

endmodule