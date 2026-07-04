`timescale 1ns/1ps

module dct_round_clip #(
    parameter ACC_W = 32,
    parameter OUT_W = 18,
    parameter FRAC_W = 14
) (
    input signed [ACC_W-1:0] sum,
    output reg signed [OUT_W-1:0] out
);

    localparam signed [ACC_W-1:0] ROUND_POS = (1 <<< (FRAC_W-1));
    localparam signed [ACC_W-1:0] MAX_OUT = (1 <<< (OUT_W-1)) - 1;
    localparam signed [ACC_W-1:0] MIN_OUT = -(1 <<< (OUT_W-1));

    reg signed [ACC_W-1:0] rounded;
    reg signed [ACC_W-1:0] shifted;

    always @* begin
        if (sum >= 0)
            rounded = sum + ROUND_POS;
        else
            rounded = sum - ROUND_POS;

        shifted = rounded >>> FRAC_W;

        if (shifted > MAX_OUT)
            out = {1'b0, {(OUT_W-1){1'b1}}};
        else if (shifted < MIN_OUT)
            out = {1'b1, {(OUT_W-1){1'b0}}};
        else
            out = shifted[OUT_W-1:0];
    end

endmodule