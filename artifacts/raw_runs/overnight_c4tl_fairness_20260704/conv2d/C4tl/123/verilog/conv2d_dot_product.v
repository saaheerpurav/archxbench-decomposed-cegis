`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter COEFF_W     = 4,
    parameter KERNEL_SIZE = 3,
    parameter ACC_W       = 16
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0]  pixels,
    input  [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0] coeffs,
    output reg [ACC_W-1:0]                       acc
);

    integer i;
    reg [DATA_W-1:0] pixel_i;
    reg [COEFF_W-1:0] coeff_i;
    reg [ACC_W-1:0] product_i;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            pixel_i   = pixels[(i+1)*DATA_W-1 -: DATA_W];
            coeff_i   = coeffs[(i+1)*COEFF_W-1 -: COEFF_W];
            product_i = pixel_i * coeff_i;
            acc       = acc + product_i;
        end
    end

endmodule