`timescale 1ns/1ps

module conv3d_mac_tree #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter OUT_W = 13
) (
    input [K1*K2*K3*DATA_W-1:0] window_flat,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    output reg [OUT_W-1:0] sum_out
);

    localparam WIN_SIZE = K1 * K2 * K3;
    localparam PROD_W = DATA_W * 2;

    integer i;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;
    reg [PROD_W-1:0] product;
    reg [OUT_W+PROD_W-1:0] acc;

    always @* begin
        acc = {(OUT_W+PROD_W){1'b0}};

        for (i = 0; i < WIN_SIZE; i = i + 1) begin
            voxel = window_flat[i*DATA_W +: DATA_W];
            coeff = kernel[i*DATA_W +: DATA_W];
            product = voxel * coeff;
            acc = acc + product;
        end

        sum_out = acc[OUT_W-1:0];
    end

endmodule