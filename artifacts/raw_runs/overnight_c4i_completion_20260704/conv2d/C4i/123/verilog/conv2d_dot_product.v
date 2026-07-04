`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter ACC_W       = 16
) (
    input      [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_flat,
    output reg [ACC_W-1:0]                         sum
);

    localparam COEFF_W = 8;
    localparam ELEMS   = KERNEL_SIZE * KERNEL_SIZE;

    integer i;

    reg [DATA_W-1:0]  pixel;
    reg [COEFF_W-1:0] coeff;
    reg [ACC_W-1:0]   raw_sum;

    function [COEFF_W-1:0] kernel_coeff;
        input integer idx;
        begin
            if (KERNEL_SIZE == 3) begin
                case (idx)
                    0: kernel_coeff = 8'd1;
                    1: kernel_coeff = 8'd2;
                    2: kernel_coeff = 8'd1;
                    3: kernel_coeff = 8'd2;
                    4: kernel_coeff = 8'd4;
                    5: kernel_coeff = 8'd2;
                    6: kernel_coeff = 8'd1;
                    7: kernel_coeff = 8'd2;
                    8: kernel_coeff = 8'd1;
                    default: kernel_coeff = {COEFF_W{1'b0}};
                endcase
            end else begin
                if (idx == (ELEMS / 2))
                    kernel_coeff = {{(COEFF_W-1){1'b0}}, 1'b1};
                else
                    kernel_coeff = {COEFF_W{1'b0}};
            end
        end
    endfunction

    always @(*) begin
        raw_sum = {ACC_W{1'b0}};

        for (i = 0; i < ELEMS; i = i + 1) begin
            pixel   = window_flat[(i+1)*DATA_W-1 -: DATA_W];
            coeff   = kernel_coeff(i);
            raw_sum = raw_sum + (pixel * coeff);
        end

        if (KERNEL_SIZE == 3)
            sum = raw_sum >> 4;
        else
            sum = raw_sum;
    end

endmodule