`timescale 1ns/1ps

module highpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter COEFF_W = 16,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input  [DATA_W*TAP_CNT-1:0]   samples,
    input  [COEFF_W*TAP_CNT-1:0]  coeffs,
    output reg signed [ACC_W-1:0] accum
);

    integer i;

    reg signed [DATA_W-1:0]  sample_i;
    reg signed [COEFF_W-1:0] coeff_i;
    reg signed [ACC_W-1:0]   sample_ext;
    reg signed [ACC_W-1:0]   coeff_ext;

    always @* begin
        accum = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample_i = samples[i*DATA_W +: DATA_W];
            coeff_i  = coeffs[i*COEFF_W +: COEFF_W];

            sample_ext = {{(ACC_W-DATA_W){sample_i[DATA_W-1]}}, sample_i};
            coeff_ext  = {{(ACC_W-COEFF_W){coeff_i[COEFF_W-1]}}, coeff_i};

            accum = accum + (sample_ext * coeff_ext);
        end
    end

endmodule