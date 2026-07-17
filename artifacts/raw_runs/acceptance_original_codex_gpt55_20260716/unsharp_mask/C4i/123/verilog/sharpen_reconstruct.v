`timescale 1ns/1ps

module sharpen_reconstruct #(
    parameter PIXEL_W = 8,
    parameter PROD_W  = 19
) (
    input  [PIXEL_W-1:0]        original,
    input  signed [PROD_W-1:0]  scaled,
    output [PIXEL_W-1:0]        pixel_out
);

    wire signed [PROD_W:0] original_ext;
    wire signed [PROD_W:0] scaled_ext;
    wire signed [PROD_W:0] recon;
    wire signed [PROD_W:0] max_pixel;
    wire signed [PROD_W:0] zero_pixel;

    assign original_ext = $signed({1'b0, {{(PROD_W-PIXEL_W){1'b0}}, original}});
    assign scaled_ext   = $signed({scaled[PROD_W-1], scaled});
    assign recon        = original_ext + scaled_ext;

    assign max_pixel  = $signed({1'b0, {{(PROD_W-PIXEL_W){1'b0}}, {PIXEL_W{1'b1}}}});
    assign zero_pixel = {PROD_W+1{1'b0}};

    assign pixel_out = (recon < zero_pixel) ? {PIXEL_W{1'b0}} :
                       (recon > max_pixel)  ? {PIXEL_W{1'b1}} :
                                              recon[PIXEL_W-1:0];

endmodule