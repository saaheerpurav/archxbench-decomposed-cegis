`timescale 1ns/1ps

module reconstruct_saturate #(
    parameter PIXEL_W = 8,
    parameter SCALE_W = 19
) (
    input  [PIXEL_W-1:0] original,
    input  signed [SCALE_W-1:0] scaled_diff,
    output [PIXEL_W-1:0] pixel_out
);

    wire signed [SCALE_W:0] original_ext;
    wire signed [SCALE_W:0] scaled_ext;
    wire signed [SCALE_W:0] value;
    wire signed [SCALE_W:0] max_value;

    assign original_ext = $signed({{(SCALE_W+1-PIXEL_W){1'b0}}, original});
    assign scaled_ext   = {scaled_diff[SCALE_W-1], scaled_diff};
    assign value        = original_ext + scaled_ext;

    assign max_value = $signed({{(SCALE_W+1-PIXEL_W){1'b0}}, {PIXEL_W{1'b1}}});

    assign pixel_out = (value < 0)         ? {PIXEL_W{1'b0}} :
                       (value > max_value) ? {PIXEL_W{1'b1}} :
                                             value[PIXEL_W-1:0];

endmodule