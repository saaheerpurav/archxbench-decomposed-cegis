`timescale 1ns/1ps

module conv2d_mac #(
    parameter DATA_W = 8,
    parameter KERNEL_SIZE = 3,
    parameter ACC_W = 20
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] flat_window,
    input  [KERNEL_SIZE*KERNEL_SIZE*16-1:0]     flat_coeffs,
    output signed [ACC_W-1:0]                   result
);

    integer i;
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] coeff_sum;
    reg signed [ACC_W-1:0] normalized;

    always @* begin
        acc = {ACC_W{1'b0}};
        coeff_sum = {ACC_W{1'b0}};

        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            acc = acc
                + ($signed({1'b0, flat_window[i*DATA_W +: DATA_W]})
                *  $signed(flat_coeffs[i*16 +: 16]));

            coeff_sum = coeff_sum + $signed(flat_coeffs[i*16 +: 16]);
        end

        if (coeff_sum != 0)
            normalized = acc / coeff_sum;
        else
            normalized = acc;
    end

    assign result = normalized;

endmodule