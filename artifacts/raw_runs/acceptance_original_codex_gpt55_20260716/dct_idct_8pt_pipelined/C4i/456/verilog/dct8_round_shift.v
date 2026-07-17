`timescale 1ns/1ps

module dct8_round_shift #(
    parameter IN_W = 32,
    parameter FRAC_BITS = 14
) (
    input signed [IN_W-1:0] in_value,
    output signed [IN_W-1:0] out_value
);

  wire signed [IN_W-1:0] round_pos = {{(IN_W-FRAC_BITS){1'b0}}, 1'b1, {(FRAC_BITS-1){1'b0}}};
  wire signed [IN_W-1:0] round_neg = -round_pos;
  wire signed [IN_W-1:0] rounded = in_value[IN_W-1] ? (in_value + round_neg) : (in_value + round_pos);

  assign out_value = rounded >>> FRAC_BITS;

endmodule