`timescale 1ns/1ps

module conv2d_output_cast #(
    parameter IN_W  = 16,
    parameter OUT_W = 12
) (
    input      [IN_W-1:0]  acc_in,
    output reg [OUT_W-1:0] pixel_out
);

    always @* begin
        pixel_out = acc_in[OUT_W-1:0];
    end

endmodule