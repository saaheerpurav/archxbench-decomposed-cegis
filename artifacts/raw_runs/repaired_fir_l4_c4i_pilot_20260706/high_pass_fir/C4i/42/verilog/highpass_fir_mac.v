`timescale 1ns/1ps

module highpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input  [DATA_W*TAP_CNT-1:0] samples_flat,
    input  [16*TAP_CNT-1:0]     coeffs_flat,
    output reg signed [ACC_W-1:0] acc_out
);

    integer i;

    reg signed [DATA_W-1:0] sample_i;
    reg signed [15:0]       coeff_i;
    reg signed [ACC_W-1:0]  product_ext;

    always @* begin
        acc_out = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample_i = samples_flat[i*DATA_W +: DATA_W];

            if (i == TAP_CNT-1)
                coeff_i = 16'sd0;
            else
                coeff_i = coeffs_flat[(i+2)*16-1 -: 16];

            product_ext = sample_i * coeff_i;
            acc_out = acc_out + product_ext;
        end
    end

endmodule