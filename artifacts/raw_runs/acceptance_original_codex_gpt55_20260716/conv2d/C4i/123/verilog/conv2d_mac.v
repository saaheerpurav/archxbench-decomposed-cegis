`timescale 1ns/1ps

module conv2d_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter ACC_W       = DATA_W + GAIN_W + 8
) (
    input      [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_flat,
    output reg [ACC_W-1:0]                          mac_out
);
    localparam K2 = KERNEL_SIZE * KERNEL_SIZE;

    integer i;
    reg [DATA_W-1:0] pix;
    reg [ACC_W-1:0]  coeff;
    reg [ACC_W-1:0]  acc;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < K2; i = i + 1) begin
            pix   = window_flat[i*DATA_W +: DATA_W];
            coeff = {ACC_W{1'b0}};

            if (KERNEL_SIZE == 3) begin
                case (i)
                    0: coeff = 1;
                    1: coeff = 2;
                    2: coeff = 1;
                    3: coeff = 2;
                    4: coeff = 4;
                    5: coeff = 2;
                    6: coeff = 1;
                    7: coeff = 2;
                    8: coeff = 1;
                    default: coeff = 0;
                endcase
            end else begin
                if (i == K2/2)
                    coeff = 1;
            end

            acc = acc + ({{(ACC_W-DATA_W){1'b0}}, pix} * coeff);
        end

        if (KERNEL_SIZE == 3)
            mac_out = acc >> 4;
        else
            mac_out = acc;
    end

endmodule