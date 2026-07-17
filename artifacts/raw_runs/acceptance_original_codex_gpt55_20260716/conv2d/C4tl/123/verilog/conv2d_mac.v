`timescale 1ns/1ps

module conv2d_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter ACC_W       = DATA_W + GAIN_W + 8
) (
    input      [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] window,
    output reg signed [ACC_W-1:0]                  sum
);
    integer i;
    reg signed [15:0] coeff;
    reg [DATA_W-1:0] pix;

    always @* begin
        sum = {ACC_W{1'b0}};

        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            pix = window[i*DATA_W +: DATA_W];

            if (KERNEL_SIZE == 3) begin
                case (i)
                    0: coeff = 16'sd1;
                    1: coeff = 16'sd2;
                    2: coeff = 16'sd1;
                    3: coeff = 16'sd2;
                    4: coeff = 16'sd4;
                    5: coeff = 16'sd2;
                    6: coeff = 16'sd1;
                    7: coeff = 16'sd2;
                    8: coeff = 16'sd1;
                    default: coeff = 16'sd0;
                endcase
            end else begin
                coeff = 16'sd1;
            end

            sum = sum + ($signed({1'b0, pix}) * coeff);
        end
    end
endmodule