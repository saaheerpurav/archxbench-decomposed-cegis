`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W = 8,
    parameter COEFF_W = 8,
    parameter KERNEL_SIZE = 3,
    parameter ACC_W = 20
) (
    input  [(KERNEL_SIZE*KERNEL_SIZE*DATA_W)-1:0]  window_flat,
    input  [(KERNEL_SIZE*KERNEL_SIZE*COEFF_W)-1:0] coeffs_flat,
    output reg [ACC_W-1:0]                         sum
);

    localparam TAP_COUNT = KERNEL_SIZE * KERNEL_SIZE;
    localparam PROD_W    = DATA_W + COEFF_W;

    integer i;

    reg [DATA_W-1:0]  pix;
    reg [COEFF_W-1:0] coeff;
    reg [PROD_W-1:0]  product;

    reg [ACC_W-1:0] raw_sum;
    reg [ACC_W-1:0] coeff_sum;

    always @(*) begin
        raw_sum   = {ACC_W{1'b0}};
        coeff_sum = {ACC_W{1'b0}};

        for (i = 0; i < TAP_COUNT; i = i + 1) begin
            pix       = window_flat[(i*DATA_W) +: DATA_W];
            coeff     = coeffs_flat[(i*COEFF_W) +: COEFF_W];
            product   = pix * coeff;
            raw_sum   = raw_sum + {{(ACC_W-PROD_W){1'b0}}, product};
            coeff_sum = coeff_sum + {{(ACC_W-COEFF_W){1'b0}}, coeff};
        end

        if (coeff_sum != {ACC_W{1'b0}})
            sum = raw_sum / coeff_sum;
        else
            sum = raw_sum;
    end

endmodule