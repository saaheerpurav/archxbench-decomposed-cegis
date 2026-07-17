`timescale 1ns/1ps

module highpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16,
    parameter ACC_W   = 64
) (
    input signed [TAP_CNT*DATA_W-1:0]  sample_window,
    input signed [TAP_CNT*COEFF_W-1:0] coeff_vector,
    output reg signed [ACC_W-1:0]      accum
);
    integer k;
    reg signed [DATA_W-1:0] sample;
    reg signed [COEFF_W-1:0] coeff;

    always @* begin
        accum = {ACC_W{1'b0}};
        for (k = 0; k < TAP_CNT; k = k + 1) begin
            sample = sample_window[k*DATA_W +: DATA_W];
            coeff  = coeff_vector[k*COEFF_W +: COEFF_W];
            accum = accum + (sample * coeff);
        end
    end
endmodule