`timescale 1ns/1ps

module conv1d_coeff_rom #(
    parameter KERNEL_SIZE = 5
) (
    output [4:0] coeff_0,
    output [4:0] coeff_1,
    output [4:0] coeff_2,
    output [4:0] coeff_3,
    output [4:0] coeff_4,
    output [4:0] coeff_5,
    output [4:0] coeff_6
);

    assign coeff_0 = (KERNEL_SIZE == 3) ? 5'd8  :
                     (KERNEL_SIZE == 5) ? 5'd2  :
                     (KERNEL_SIZE == 7) ? 5'd1  : 5'd2;

    assign coeff_1 = (KERNEL_SIZE == 3) ? 5'd16 :
                     (KERNEL_SIZE == 5) ? 5'd8  :
                     (KERNEL_SIZE == 7) ? 5'd4  : 5'd8;

    assign coeff_2 = (KERNEL_SIZE == 3) ? 5'd8  :
                     (KERNEL_SIZE == 5) ? 5'd12 :
                     (KERNEL_SIZE == 7) ? 5'd7  : 5'd12;

    assign coeff_3 = (KERNEL_SIZE == 3) ? 5'd0  :
                     (KERNEL_SIZE == 5) ? 5'd8  :
                     (KERNEL_SIZE == 7) ? 5'd8  : 5'd8;

    assign coeff_4 = (KERNEL_SIZE == 3) ? 5'd0  :
                     (KERNEL_SIZE == 5) ? 5'd2  :
                     (KERNEL_SIZE == 7) ? 5'd7  : 5'd2;

    assign coeff_5 = (KERNEL_SIZE == 7) ? 5'd4 : 5'd0;

    assign coeff_6 = (KERNEL_SIZE == 7) ? 5'd1 : 5'd0;

endmodule