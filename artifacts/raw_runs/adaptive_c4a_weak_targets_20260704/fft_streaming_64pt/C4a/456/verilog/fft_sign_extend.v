`timescale 1ns/1ps

module fft_sign_extend #(
    parameter IN_W  = 16,
    parameter OUT_W = 20
) (
    input  signed [IN_W-1:0]  in_real,
    input  signed [IN_W-1:0]  in_imag,
    output signed [OUT_W-1:0] out_real,
    output signed [OUT_W-1:0] out_imag
);

    assign out_real = {{(OUT_W-IN_W){in_real[IN_W-1]}}, in_real};
    assign out_imag = {{(OUT_W-IN_W){in_imag[IN_W-1]}}, in_imag};

endmodule