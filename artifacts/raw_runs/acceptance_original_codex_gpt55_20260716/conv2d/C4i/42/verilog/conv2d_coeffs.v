`timescale 1ns/1ps

module conv2d_coeffs #(
    parameter KERNEL_SIZE = 3
) (
    output [8*KERNEL_SIZE*KERNEL_SIZE-1:0] coeff_flat
);

    assign coeff_flat[8*1-1:8*0] = 8'd1;
    assign coeff_flat[8*2-1:8*1] = 8'd2;
    assign coeff_flat[8*3-1:8*2] = 8'd1;

    assign coeff_flat[8*4-1:8*3] = 8'd2;
    assign coeff_flat[8*5-1:8*4] = 8'd4;
    assign coeff_flat[8*6-1:8*5] = 8'd2;

    assign coeff_flat[8*7-1:8*6] = 8'd1;
    assign coeff_flat[8*8-1:8*7] = 8'd2;
    assign coeff_flat[8*9-1:8*8] = 8'd1;

endmodule