`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter COEFF_W     = 8,
    parameter KERNEL_SIZE = 3,
    parameter ACC_W       = DATA_W + 12
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0]  pixels,
    input  [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0] coeffs,
    output reg [ACC_W-1:0]                       sum
);
    integer i;
    reg [DATA_W-1:0]  pix;
    reg [COEFF_W-1:0] coef;

    always @* begin
        sum = {ACC_W{1'b0}};
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            pix  = pixels[(i+1)*DATA_W-1 -: DATA_W];
            coef = coeffs[(i+1)*COEFF_W-1 -: COEFF_W];
            sum  = sum + (pix * coef);
        end
    end
endmodule