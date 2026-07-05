`timescale 1ns/1ps

module conv2d_bias_add #(
    parameter COUT = 8,
    parameter BIAS_W = 16,
    parameter ACC_W = 32
)(
    input signed [ACC_W-1:0] sum_in,
    input [COUT*BIAS_W-1:0] bias,
    input [31:0] out_ch,
    output reg signed [ACC_W-1:0] sum_out
);

    integer ch;
    reg signed [BIAS_W-1:0] selected_bias;
    reg signed [ACC_W-1:0] bias_ext;

    always @* begin
        selected_bias = {BIAS_W{1'b0}};

        for (ch = 0; ch < COUT; ch = ch + 1) begin
            if (out_ch == ch[31:0]) begin
                selected_bias = bias[ch*BIAS_W +: BIAS_W];
            end
        end

        bias_ext = {{(ACC_W-BIAS_W){selected_bias[BIAS_W-1]}}, selected_bias};
        sum_out = sum_in + bias_ext;
    end

endmodule