`timescale 1ns/1ps

module dct1d_8_round_sat #(
    parameter ACC_W = 32,
    parameter OUT_W = 18,
    parameter SHIFT = 14
) (
    input  signed [ACC_W-1:0] acc,
    output reg signed [OUT_W-1:0] out
);

    localparam signed [OUT_W-1:0] OUT_MAX = {1'b0, {(OUT_W-1){1'b1}}};
    localparam signed [OUT_W-1:0] OUT_MIN = {1'b1, {(OUT_W-1){1'b0}}};

    wire signed [ACC_W-1:0] round_bias;
    wire signed [ACC_W-1:0] rounded;
    wire signed [ACC_W-1:0] shifted;

    wire signed [ACC_W-1:0] out_max_ext;
    wire signed [ACC_W-1:0] out_min_ext;

    assign round_bias = acc[ACC_W-1] ? -(1 <<< (SHIFT-1)) :
                                       (1 <<< (SHIFT-1));

    assign rounded = acc + round_bias;
    assign shifted = rounded >>> SHIFT;

    assign out_max_ext = {{(ACC_W-OUT_W){OUT_MAX[OUT_W-1]}}, OUT_MAX};
    assign out_min_ext = {{(ACC_W-OUT_W){OUT_MIN[OUT_W-1]}}, OUT_MIN};

    always @* begin
        if (shifted > out_max_ext)
            out = OUT_MAX;
        else if (shifted < out_min_ext)
            out = OUT_MIN;
        else
            out = shifted[OUT_W-1:0];
    end

endmodule