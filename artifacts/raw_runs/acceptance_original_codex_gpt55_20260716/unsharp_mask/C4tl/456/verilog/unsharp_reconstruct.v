module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input  [PIXEL_W-1:0] original,
    input  signed [PIXEL_W+GAIN_W:0] scaled,
    output [PIXEL_W-1:0] pixel_out
);

    localparam SUM_W = PIXEL_W + GAIN_W + 2;

    localparam signed [SUM_W-1:0] MAX_PIXEL =
        $signed({1'b0, {PIXEL_W{1'b1}}});

    wire signed [SUM_W-1:0] original_ext;
    wire signed [SUM_W-1:0] scaled_ext;
    wire signed [SUM_W-1:0] sharp;

    assign original_ext = $signed({1'b0, original});
    assign scaled_ext   = scaled;
    assign sharp        = original_ext + scaled_ext;

    assign pixel_out = (sharp < 0) ? {PIXEL_W{1'b0}} :
                       (sharp > MAX_PIXEL) ? {PIXEL_W{1'b1}} :
                       sharp[PIXEL_W-1:0];

endmodule