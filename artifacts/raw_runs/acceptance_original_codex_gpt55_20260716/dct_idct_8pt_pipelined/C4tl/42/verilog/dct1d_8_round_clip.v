`timescale 1ns/1ps

module dct1d_8_round_clip #(
    parameter ACC_W = 32,
    parameter OUT_W = 18,
    parameter FRAC_W = 14
) (
    input signed [ACC_W-1:0] acc,
    output reg signed [OUT_W-1:0] y
);

    reg signed [ACC_W-1:0] rounded;
    reg signed [ACC_W-1:0] shifted;
    reg signed [ACC_W-1:0] max_val;
    reg signed [ACC_W-1:0] min_val;

    always @* begin
        if (acc >= 0)
            rounded = acc + ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));
        else
            rounded = acc - ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));

        shifted = rounded >>> FRAC_W;
        max_val = ({{(ACC_W-OUT_W+1){1'b0}}, {(OUT_W-1){1'b1}}});
        min_val = -({{(ACC_W-OUT_W+1){1'b0}}, 1'b1, {(OUT_W-1){1'b0}}});

        if (shifted > max_val)
            y = {1'b0, {(OUT_W-1){1'b1}}};
        else if (shifted < min_val)
            y = {1'b1, {(OUT_W-1){1'b0}}};
        else
            y = shifted[OUT_W-1:0];
    end

endmodule