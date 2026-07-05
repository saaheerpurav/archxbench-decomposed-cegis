`timescale 1ns/1ps

module multich_conv2d_mac #(
    parameter ELEMS = 27,
    parameter DATA_W = 8,
    parameter ACC_W = 32
)(
    input  [ELEMS*DATA_W-1:0] window_flat,
    input  [ELEMS*DATA_W-1:0] kernel_flat,
    output reg [ACC_W-1:0] sum
);

    integer i;
    reg [DATA_W-1:0] win_val;
    reg [DATA_W-1:0] ker_val;
    reg [(2*DATA_W)-1:0] product;

    always @* begin
        sum = {ACC_W{1'b0}};

        for (i = 0; i < ELEMS; i = i + 1) begin
            win_val = window_flat[i*DATA_W +: DATA_W];
            ker_val = kernel_flat[i*DATA_W +: DATA_W];
            product = win_val * ker_val;
            sum = sum + {{(ACC_W-(2*DATA_W)){1'b0}}, product};
        end
    end

endmodule