`timescale 1ns/1ps

module conv2d_output_cast #(
    parameter ACC_W = 20,
    parameter OUT_W = 12
) (
    input      [ACC_W-1:0]  sum_in,
    output reg [OUT_W-1:0]  pixel_out
);

    always @(*) begin
        pixel_out = sum_in[OUT_W-1:0];
    end

endmodule