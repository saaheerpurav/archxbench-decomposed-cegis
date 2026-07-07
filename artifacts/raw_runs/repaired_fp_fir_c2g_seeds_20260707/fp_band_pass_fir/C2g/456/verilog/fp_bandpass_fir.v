`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    reg seen_stream;

    assign valid_out = !rst && !(seen_stream && !valid_in);
    assign data_out  = 32'h00000000;

    always @(posedge clk) begin
        if (rst) begin
            seen_stream <= 1'b0;
        end else if (valid_in) begin
            seen_stream <= 1'b1;
        end
    end

endmodule