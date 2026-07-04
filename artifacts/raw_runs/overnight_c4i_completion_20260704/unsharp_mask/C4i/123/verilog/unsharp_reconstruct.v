`timescale 1ns/1ps

module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter PROD_W = 18
) (
    input  [PIXEL_W-1:0]        original,
    input  signed [PROD_W-1:0]  scaled,
    output [PIXEL_W-1:0]        pixel_out
);

    localparam ACC_W = ((PROD_W > PIXEL_W) ? PROD_W : PIXEL_W) + 1;

    wire signed [ACC_W-1:0] original_ext;
    wire signed [ACC_W-1:0] scaled_ext;
    wire signed [ACC_W-1:0] result;
    wire signed [ACC_W-1:0] max_value;

    assign original_ext = {{(ACC_W-PIXEL_W){1'b0}}, original};
    assign scaled_ext   = {{(ACC_W-PROD_W){scaled[PROD_W-1]}}, scaled};
    assign result       = original_ext + scaled_ext;

    assign max_value = {{(ACC_W-PIXEL_W){1'b0}}, {PIXEL_W{1'b1}}};

    assign pixel_out = (result < 0)         ? {PIXEL_W{1'b0}} :
                       (result > max_value) ? {PIXEL_W{1'b1}} :
                                              result[PIXEL_W-1:0];

endmodule