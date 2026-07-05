`timescale 1ns/1ps

module multich_conv2d_kernel_select #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter DATA_W = 8
)(
    input  [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input  [31:0] out_ch,
    output reg [CIN*K*K*DATA_W-1:0] kernel_slice
);

    localparam ELEMS = CIN * K * K;

    integer i;
    integer src_elem;

    always @* begin
        kernel_slice = {(CIN*K*K*DATA_W){1'b0}};

        if (out_ch < COUT) begin
            for (i = 0; i < ELEMS; i = i + 1) begin
                src_elem = (out_ch * ELEMS) + i;
                kernel_slice[i*DATA_W +: DATA_W] =
                    kernel[src_elem*DATA_W +: DATA_W];
            end
        end
    end

endmodule