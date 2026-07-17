`timescale 1ns/1ps

module fp_fir_output_select (
    input wire valid_in,
    input wire [31:0] fir_value,
    output wire [31:0] data_out
);

    assign data_out = valid_in ? fir_value : 32'h00000000;

endmodule