`timescale 1ns/1ps

module dct1d_8_round_sat #(
    parameter IN_W = 32,
    parameter OUT_W = 18,
    parameter FRAC_W = 14
) (
    input signed [IN_W-1:0] in_value,
    output signed [OUT_W-1:0] out_value
);

    localparam signed [OUT_W-1:0] MAX_OUT = {1'b0, {OUT_W-1{1'b1}}};
    localparam signed [OUT_W-1:0] MIN_OUT = {1'b1, {OUT_W-1{1'b0}}};

    wire signed [IN_W-1:0] round_bias = in_value[IN_W-1] ? -{{(IN_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}}
                                                         :  {{(IN_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}};
    wire signed [IN_W-1:0] rounded = in_value + round_bias;
    wire signed [IN_W-1:0] shifted = rounded >>> FRAC_W;

    assign out_value = (shifted > {{(IN_W-OUT_W){MAX_OUT[OUT_W-1]}}, MAX_OUT}) ? MAX_OUT :
                       (shifted < {{(IN_W-OUT_W){MIN_OUT[OUT_W-1]}}, MIN_OUT}) ? MIN_OUT :
                       shifted[OUT_W-1:0];

endmodule