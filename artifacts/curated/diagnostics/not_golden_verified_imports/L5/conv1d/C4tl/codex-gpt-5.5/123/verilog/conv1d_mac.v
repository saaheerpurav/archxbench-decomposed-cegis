`timescale 1ns/1ps

module conv1d_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter COEFF_W     = 8,
    parameter ACC_W       = 20
) (
    input  [DATA_W*KERNEL_SIZE-1:0]  window_flat,
    input  [COEFF_W*KERNEL_SIZE-1:0] coeffs_flat,
    output [ACC_W-1:0]               sum
);

    integer j;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] sample_j;
    reg [COEFF_W-1:0] coeff_j;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
            sample_j = window_flat[DATA_W*j +: DATA_W];
            coeff_j  = coeffs_flat[COEFF_W*j +: COEFF_W];
            acc = acc + (sample_j * coeff_j);
        end
    end

    assign sum = acc;

endmodule