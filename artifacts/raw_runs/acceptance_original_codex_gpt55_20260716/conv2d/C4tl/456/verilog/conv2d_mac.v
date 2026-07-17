`timescale 1ns/1ps

module conv2d_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter ACC_W       = DATA_W + GAIN_W + 8
) (
    input  [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_flat,
    output [ACC_W-1:0] mac_out
);
    integer i;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] pix;

    function [7:0] coeff;
        input integer idx;
        begin
            if (KERNEL_SIZE == 3) begin
                case (idx)
                    0: coeff = 8'd1;
                    1: coeff = 8'd2;
                    2: coeff = 8'd1;
                    3: coeff = 8'd2;
                    4: coeff = 8'd4;
                    5: coeff = 8'd2;
                    6: coeff = 8'd1;
                    7: coeff = 8'd2;
                    8: coeff = 8'd1;
                    default: coeff = 8'd0;
                endcase
            end else begin
                coeff = 8'd1;
            end
        end
    endfunction

    always @* begin
        acc = {ACC_W{1'b0}};
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            pix = window_flat[i*DATA_W +: DATA_W];
            acc = acc + (pix * coeff(i));
        end
    end

    assign mac_out = acc;
endmodule