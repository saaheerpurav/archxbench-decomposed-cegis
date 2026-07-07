`timescale 1ns/1ps

module hpf_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input      [DATA_W*TAP_CNT-1:0] samples_flat,
    output reg signed [ACC_W-1:0]   acc_out
);
    wire signed [15:0] coeff [0:TAP_CNT-1];

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : coeffs
            hpf_coeff_rom coeff_rom_i (
                .index(gi[6:0]),
                .coeff(coeff[gi])
            );
        end
    endgenerate

    integer i;
    reg signed [DATA_W-1:0] sample_i;
    reg signed [ACC_W-1:0] product_i;

    always @* begin
        acc_out = {ACC_W{1'b0}};
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample_i = samples_flat[i*DATA_W +: DATA_W];
            product_i = sample_i * coeff[i];
            acc_out = acc_out + product_i;
        end
    end
endmodule