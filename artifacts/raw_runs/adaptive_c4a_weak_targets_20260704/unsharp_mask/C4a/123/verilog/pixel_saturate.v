`timescale 1ns/1ps

module pixel_saturate #(
    parameter PIXEL_W = 8,
    parameter IN_W = 20
) (
    input  signed [IN_W-1:0] value_in,
    output [PIXEL_W-1:0] pixel_out
);
    localparam [PIXEL_W-1:0] PIXEL_MAX = {PIXEL_W{1'b1}};
    wire signed [IN_W-1:0] max_signed = {{(IN_W-PIXEL_W){1'b0}}, PIXEL_MAX};

    assign pixel_out = (value_in < 0) ? {PIXEL_W{1'b0}} :
                       (value_in > max_signed) ? PIXEL_MAX :
                       value_in[PIXEL_W-1:0];

endmodule