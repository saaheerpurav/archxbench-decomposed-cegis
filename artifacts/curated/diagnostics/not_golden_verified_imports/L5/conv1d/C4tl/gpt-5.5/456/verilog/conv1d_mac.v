`timescale 1ns/1ps

module conv1d_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter COEFF_W     = 4,
    parameter ACC_W       = 16
) (
    input  [DATA_W*KERNEL_SIZE-1:0]  window,
    input  [COEFF_W*KERNEL_SIZE-1:0] coeffs,
    output [ACC_W-1:0]               sum
);

    wire [ACC_W-1:0] partial [0:KERNEL_SIZE-1];

    genvar i;
    generate
        for (i = 0; i < KERNEL_SIZE; i = i + 1) begin : g_products
            wire [DATA_W-1:0] sample;
            wire [COEFF_W-1:0] coeff;

            assign sample = window[DATA_W*(KERNEL_SIZE-i)-1 -: DATA_W];
            assign coeff  = coeffs[COEFF_W*(KERNEL_SIZE-i)-1 -: COEFF_W];

            assign partial[i] = sample * coeff;
        end
    endgenerate

    generate
        if (KERNEL_SIZE == 3) begin : g_sum3
            assign sum = partial[0] + partial[1] + partial[2];
        end else if (KERNEL_SIZE == 5) begin : g_sum5
            assign sum = partial[0] + partial[1] + partial[2] + partial[3] + partial[4];
        end else if (KERNEL_SIZE == 7) begin : g_sum7
            assign sum = partial[0] + partial[1] + partial[2] + partial[3] + partial[4] + partial[5] + partial[6];
        end else begin : g_sum_default
            assign sum = {ACC_W{1'b0}};
        end
    endgenerate

endmodule