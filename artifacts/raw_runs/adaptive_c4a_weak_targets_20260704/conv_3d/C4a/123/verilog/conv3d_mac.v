`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter LOG_KW = 4,
    parameter ACC_W = (2*DATA_W) + LOG_KW + 2
) (
    input  [K1*K2*K3*DATA_W-1:0] window,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output [ACC_W-1:0] acc
);

    localparam KTOTAL = K1 * K2 * K3;

    reg [ACC_W-1:0] acc_r;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;
    reg [(2*DATA_W)-1:0] product;
    integer i;

    assign acc = acc_r;

    always @* begin
        acc_r = {ACC_W{1'b0}};

        for (i = 0; i < KTOTAL; i = i + 1) begin
            voxel   = window[i*DATA_W +: DATA_W];
            coeff   = kernel[i*DATA_W +: DATA_W];
            product = voxel * coeff;
            acc_r   = acc_r + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
        end
    end

endmodule