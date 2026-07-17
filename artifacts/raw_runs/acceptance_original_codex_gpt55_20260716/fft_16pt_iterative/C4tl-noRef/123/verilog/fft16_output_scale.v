module fft16_output_scale #(
    parameter N = 16,
    parameter DATA_W = 12,
    parameter GAIN_W = 4
) (
    input  mode, // 0: FFT pass-through, 1: IFFT divide by N
    input  signed [DATA_W+GAIN_W-1:0] data_real_in [0:N-1],
    input  signed [DATA_W+GAIN_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1]
);

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : gen_output_scale
            assign data_real_out[i] = mode ? (data_real_in[i] >>> GAIN_W)
                                           :  data_real_in[i];

            assign data_imag_out[i] = mode ? (data_imag_in[i] >>> GAIN_W)
                                           :  data_imag_in[i];
        end
    endgenerate

endmodule