`timescale 1ns/1ps

module conv2d_mac #(
    parameter CIN = 3,
    parameter K = 3,
    parameter DATA_W = 8,
    parameter BIAS_W = 16,
    parameter ACC_W = 32
)(
    input  [CIN*K*K*DATA_W-1:0] window,
    input  [CIN*K*K*DATA_W-1:0] kernel,
    input  [BIAS_W-1:0] bias,
    output [ACC_W-1:0] sum
);

    localparam integer TAPS = CIN * K * K;

    integer i;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] pix;
    reg [DATA_W-1:0] weight;
    reg [2*DATA_W-1:0] product;

    always @* begin
        acc = {{(ACC_W-BIAS_W){1'b0}}, bias};

        for (i = 0; i < TAPS; i = i + 1) begin
            pix = window[i*DATA_W +: DATA_W];
            weight = kernel[i*DATA_W +: DATA_W];
            product = pix * weight;
            acc = acc + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
        end
    end

    assign sum = acc;

endmodule