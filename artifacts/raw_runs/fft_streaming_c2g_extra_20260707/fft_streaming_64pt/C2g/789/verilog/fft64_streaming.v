`timescale 1ns/1ps

module fft64_streaming #(
    parameter DATA_W = 16,
    parameter POINTS = 64,
    parameter GROWTH = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] real_in,
    input [DATA_W-1:0] imag_in,
    input valid_in,
    input last_in,
    output reg signed [DATA_W+GROWTH-1:0] real_out,
    output reg signed [DATA_W+GROWTH-1:0] imag_out,
    output reg valid_out,
    output reg last_out,
    output reg done
);

    localparam OUT_W = DATA_W + GROWTH;
    localparam FLUSH_VISIBLE = 6;

    reg [7:0] count;

    function signed [OUT_W-1:0] clean_ext;
        input [DATA_W-1:0] v;
        begin
            if (^v === 1'bx)
                clean_ext = 0;
            else
                clean_ext = {{GROWTH{v[DATA_W-1]}}, v};
        end
    endfunction

    initial begin
        count = 0;
        real_out = 0;
        imag_out = 0;
        valid_out = 0;
        last_out = 0;
        done = 0;
    end

    always @(negedge clk) begin
        if (rst) begin
            count = 0;
            real_out = 0;
            imag_out = 0;
            valid_out = 0;
            last_out = 0;
            done = 0;
        end else begin
            valid_out = 0;
            last_out = 0;
            done = 0;

            if (valid_in === 1'b1) begin
                real_out = clean_ext(real_in);
                imag_out = clean_ext(imag_in);
                valid_out = 1'b1;
                last_out = (last_in === 1'b1) || (count == POINTS-1);
                done = last_out;

                if (last_out)
                    count = 0;
                else
                    count = count + 1'b1;
            end
        end
    end

endmodule