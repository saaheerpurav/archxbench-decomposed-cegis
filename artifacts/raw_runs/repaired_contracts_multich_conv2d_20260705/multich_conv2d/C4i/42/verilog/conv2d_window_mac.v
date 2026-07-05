`timescale 1ns/1ps

module conv2d_window_mac #(
    parameter CIN = 3,
    parameter K = 3,
    parameter DATA_W = 8,
    parameter ACC_W = 32
)(
    input  [CIN*K*K*DATA_W-1:0] window_flat,
    input  [CIN*K*K*DATA_W-1:0] kernel_flat,
    output reg [ACC_W-1:0] sum
);
    localparam TAP_N = CIN * K * K;

    integer i;
    reg [DATA_W-1:0] pix;
    reg [DATA_W-1:0] wt;
    reg [2*DATA_W-1:0] product;

    always @* begin
        sum = {ACC_W{1'b0}};

        for (i = 0; i < TAP_N; i = i + 1) begin
            pix = window_flat[i*DATA_W +: DATA_W];
            wt  = kernel_flat[i*DATA_W +: DATA_W];
            product = pix * wt;
            sum = sum + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
        end
    end
endmodule