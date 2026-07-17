`timescale 1ns/1ps

module highpass_fir_q15_shift #(
    parameter ACC_W = 64,
    parameter OUT_W = 24
) (
    input signed [ACC_W-1:0] acc_in,
    output signed [OUT_W-1:0] data_out
);
    assign data_out = $signed(acc_in >>> 15);
endmodule