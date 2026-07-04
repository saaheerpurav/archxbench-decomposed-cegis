`timescale 1ns/1ps

module reconstruct_sat #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input  [PIXEL_W-1:0] original,
    input  signed [PIXEL_W+GAIN_W:0] scaled,
    output [PIXEL_W-1:0] pixel_out
);
    localparam EXT_W = PIXEL_W + GAIN_W + 2;

    wire signed [EXT_W-1:0] original_ext;
    wire signed [EXT_W-1:0] scaled_ext;
    wire signed [EXT_W-1:0] result_ext;
    wire signed [EXT_W-1:0] max_ext;

    assign original_ext = $signed({{(EXT_W-PIXEL_W){1'b0}}, original});
    assign scaled_ext   = {{(EXT_W-(PIXEL_W+GAIN_W+1)){scaled[PIXEL_W+GAIN_W]}}, scaled};
    assign result_ext   = original_ext + scaled_ext;

    assign max_ext = $signed({{(EXT_W-PIXEL_W){1'b0}}, {PIXEL_W{1'b1}}});

    assign pixel_out = (result_ext < 0)       ? {PIXEL_W{1'b0}} :
                       (result_ext > max_ext) ? {PIXEL_W{1'b1}} :
                                                 result_ext[PIXEL_W-1:0];

endmodule