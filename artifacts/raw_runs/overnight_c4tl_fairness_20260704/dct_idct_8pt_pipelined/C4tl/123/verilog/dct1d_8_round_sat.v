`timescale 1ns/1ps

module dct1d_8_round_sat #(
    parameter IN_W = 33,
    parameter OUT_W = 18,
    parameter SHIFT = 14
) (
    input signed [IN_W-1:0] in_value,
    output reg signed [OUT_W-1:0] out_value
);

    localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {(OUT_W-1){1'b1}}};
    localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {(OUT_W-1){1'b0}}};

    reg signed [IN_W-1:0] rounded;
    reg signed [IN_W-1:0] shifted;
    reg overflow_pos;
    reg overflow_neg;

    always @* begin
        if (in_value[IN_W-1])
            rounded = in_value + ({{(IN_W-1){1'b0}}, 1'b1} << (SHIFT-1)) - 1;
        else
            rounded = in_value + ({{(IN_W-1){1'b0}}, 1'b1} << (SHIFT-1));

        shifted = rounded >>> SHIFT;

        overflow_pos = (shifted > {{(IN_W-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT});
        overflow_neg = (shifted < {{(IN_W-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT});

        if (overflow_pos)
            out_value = MAX_OUT;
        else if (overflow_neg)
            out_value = MIN_OUT;
        else
            out_value = shifted[OUT_W-1:0];
    end

endmodule