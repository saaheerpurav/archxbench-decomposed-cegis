`timescale 1ns/1ps

module conv2d_bias_clamp #(
    parameter ACC_W = 32,
    parameter BIAS_W = 16,
    parameter OUT_W = 16
)(
    input  [ACC_W-1:0]  sum_in,
    input  [BIAS_W-1:0] bias_in,
    output reg [OUT_W-1:0] pixel_out
);

    localparam MAX_AB_W = (ACC_W > BIAS_W) ? ACC_W : BIAS_W;
    localparam BASE_W   = (MAX_AB_W > OUT_W) ? MAX_AB_W : OUT_W;
    localparam EXT_W    = BASE_W + 1;

    reg [EXT_W-1:0] biased;
    reg [EXT_W-1:0] max_out;

    always @* begin
        biased =
            {{(EXT_W-ACC_W){1'b0}}, sum_in} +
            {{(EXT_W-BIAS_W){1'b0}}, bias_in};

        max_out = {{(EXT_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

        if (biased > max_out)
            pixel_out = {OUT_W{1'b1}};
        else
            pixel_out = biased[OUT_W-1:0];
    end

endmodule