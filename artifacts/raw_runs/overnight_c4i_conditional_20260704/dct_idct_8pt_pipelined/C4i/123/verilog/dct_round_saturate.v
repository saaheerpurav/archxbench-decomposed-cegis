`timescale 1ns/1ps

module dct_round_saturate #(
    parameter ACC_W = 32,
    parameter OUT_W = 18,
    parameter FRAC_BITS = 14
) (
    input  signed [ACC_W-1:0] in_value,
    output reg signed [OUT_W-1:0] out_value
);
    localparam EXT_W = ACC_W + 1;

    localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {(OUT_W-1){1'b1}}};
    localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {(OUT_W-1){1'b0}}};

    wire signed [EXT_W-1:0] in_ext = {in_value[ACC_W-1], in_value};

    wire signed [EXT_W-1:0] half_lsb =
        {{(EXT_W-1){1'b0}}, 1'b1} << (FRAC_BITS - 1);

    wire signed [EXT_W-1:0] rounded =
        in_value[ACC_W-1] ? (in_ext - half_lsb) : (in_ext + half_lsb);

    wire signed [EXT_W-1:0] shifted = rounded >>> FRAC_BITS;

    wire signed [EXT_W-1:0] max_ext =
        {{(EXT_W-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT};

    wire signed [EXT_W-1:0] min_ext =
        {{(EXT_W-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT};

    always @* begin
        if (shifted > max_ext)
            out_value = MAX_OUT;
        else if (shifted < min_ext)
            out_value = MIN_OUT;
        else
            out_value = shifted[OUT_W-1:0];
    end
endmodule