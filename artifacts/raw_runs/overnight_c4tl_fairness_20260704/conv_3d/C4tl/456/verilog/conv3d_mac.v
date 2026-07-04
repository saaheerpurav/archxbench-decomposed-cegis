`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter LOG_KW = 4,
    parameter ACC_W = (2 * DATA_W) + LOG_KW + 4
) (
    input [K1*K2*K3*DATA_W-1:0] window_flat,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    output reg [ACC_W-1:0] sum
);
    localparam KW = K1 * K2 * K3;

    integer i;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;
    reg [(2*DATA_W)-1:0] product;

    always @* begin
        sum = 0;
        for (i = 0; i < KW; i = i + 1) begin
            voxel = window_flat[i*DATA_W +: DATA_W];
            coeff = kernel[i*DATA_W +: DATA_W];
            product = voxel * coeff;
            sum = sum + product;
        end
    end
endmodule