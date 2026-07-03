`timescale 1ns/1ps

module conv1d_coeff_rom #(
    parameter KERNEL_SIZE = 5
) (
    output [KERNEL_SIZE*4-1:0] coeffs
);

    generate
        if (KERNEL_SIZE == 3) begin : g_k3
            assign coeffs = {4'd2, 4'd12, 4'd2};
        end else if (KERNEL_SIZE == 5) begin : g_k5
            assign coeffs = {4'd2, 4'd8, 4'd12, 4'd8, 4'd2};
        end else if (KERNEL_SIZE == 7) begin : g_k7
            assign coeffs = {4'd1, 4'd2, 4'd4, 4'd8, 4'd4, 4'd2, 4'd1};
        end else begin : g_default
            assign coeffs = {KERNEL_SIZE{4'd0}};
        end
    endgenerate

endmodule