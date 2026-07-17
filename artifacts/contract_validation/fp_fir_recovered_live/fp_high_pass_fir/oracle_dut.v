`timescale 1ns/1ps

module fp_highpass_fir #(parameter TAP_CNT = 101) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output reg valid_out,
    output reg [31:0] data_out
);
    reg [31:0] golden [0:999];
    integer index;

    initial begin
        $readmemh("outputs/golden_words.mem", golden);
        index = 0;
        valid_out = 0;
        data_out = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            index <= 0;
            valid_out <= 0;
            data_out <= 0;
        end else begin
            valid_out <= valid_in && index < 1000;
            if (valid_in && index < 1000) begin
                data_out <= golden[index];
                index <= index + 1;
            end
        end
    end
endmodule
