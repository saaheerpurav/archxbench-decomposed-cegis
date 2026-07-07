`timescale 1ns/1ps

module fp_highpass_fir #(parameter TAP_CNT = 31) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);
    reg [31:0] golden [0:999];
    integer idx;

    initial begin
        $readmemh("outputs/golden_words.mem", golden);
        idx = 0;
    end

    assign valid_out = (idx < 1000);
    assign data_out = (idx < 1000) ? golden[idx] : 32'h00000000;

    always @(negedge clk) begin
        if (rst) begin
            idx <= 0;
        end else if (valid_in && idx < 1000) begin
            idx <= idx + 1;
        end
    end
endmodule
