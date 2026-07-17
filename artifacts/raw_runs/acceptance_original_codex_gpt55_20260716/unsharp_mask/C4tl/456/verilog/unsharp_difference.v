module unsharp_difference #(
    parameter PIXEL_W = 8
) (
    input  [PIXEL_W-1:0] original,
    input  [PIXEL_W-1:0] blurred,
    output signed [PIXEL_W:0] diff
);

    wire signed [PIXEL_W:0] original_ext;
    wire signed [PIXEL_W:0] blurred_ext;

    assign original_ext = $signed({1'b0, original});
    assign blurred_ext  = $signed({1'b0, blurred});

    assign diff = original_ext - blurred_ext;

endmodule