`timescale 1ns/1ps

module conv3d_mac_array #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter SUM_W = 13
) (
    input  [K1*K2*K3*DATA_W-1:0] tap_voxels,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output reg [SUM_W-1:0] sum_out
);

    localparam K_TOTAL = K1 * K2 * K3;

    integer i;
    reg [2*DATA_W-1:0] product;

    always @* begin
        sum_out = {SUM_W{1'b0}};

        for (i = 0; i < K_TOTAL; i = i + 1) begin
            product =
                tap_voxels[i*DATA_W +: DATA_W] *
                kernel[i*DATA_W +: DATA_W];

            sum_out = sum_out + product;
        end
    end

endmodule