`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter LOG_KW = 4,
    parameter ACC_W = (2*DATA_W) + LOG_KW + 8
) (
    input  [K1*K2*K3*DATA_W-1:0] window,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output [ACC_W-1:0] sum
);

    localparam KW = K1 * K2 * K3;

    integer i;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] voxel_i;
    reg [DATA_W-1:0] coeff_i;
    reg [(2*DATA_W)-1:0] product_i;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < KW; i = i + 1) begin
            voxel_i   = window[i*DATA_W +: DATA_W];
            coeff_i   = kernel[i*DATA_W +: DATA_W];
            product_i = voxel_i * coeff_i;
            acc       = acc + product_i;
        end
    end

    assign sum = acc;

endmodule