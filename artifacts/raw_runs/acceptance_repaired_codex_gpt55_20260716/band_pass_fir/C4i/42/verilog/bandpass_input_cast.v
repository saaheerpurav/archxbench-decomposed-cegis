`timescale 1ns/1ps

module bandpass_input_cast #(
    parameter DATA_W = 20
) (
    input      [DATA_W-1:0] data_in,
    output signed [DATA_W-1:0] sample_out
);

    assign sample_out = $signed(data_in);

endmodule