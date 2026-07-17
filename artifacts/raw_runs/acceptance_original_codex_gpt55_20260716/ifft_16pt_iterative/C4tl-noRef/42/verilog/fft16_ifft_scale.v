module fft16_ifft_scale #(
    parameter N      = 16,
    parameter DATA_W = 12,
    parameter GAIN_W = 4
) (
    input  signed [DATA_W+GAIN_W-1:0] data_real_in [0:N-1],
    input  signed [DATA_W+GAIN_W-1:0] data_imag_in [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_real_out [0:N-1],
    output signed [DATA_W+GAIN_W-1:0] data_imag_out [0:N-1]
);

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : gen_ifft_scale
            assign data_real_out[i] = data_real_in[i] >>> GAIN_W;
            assign data_imag_out[i] = data_imag_in[i] >>> GAIN_W;
        end
    endgenerate

endmodule