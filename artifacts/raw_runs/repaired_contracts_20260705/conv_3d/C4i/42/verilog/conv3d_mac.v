`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter LOG_KW = 5
) (
    input  [K1*K2*K3*DATA_W-1:0] window_flat,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output [DATA_W+LOG_KW-1:0] sum
);
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam PROD_W = 2 * DATA_W;
    localparam ACC_W = PROD_W + LOG_KW;

    integer i;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < KW; i = i + 1) begin
            voxel = window_flat[i*DATA_W +: DATA_W];
            coeff = kernel[i*DATA_W +: DATA_W];
            acc = acc + (voxel * coeff);
        end
    end

    assign sum = acc[OUT_W-1:0];

endmodule