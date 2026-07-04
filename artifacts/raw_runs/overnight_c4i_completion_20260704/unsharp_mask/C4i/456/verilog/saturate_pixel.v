`timescale 1ns/1ps

module saturate_pixel #(
    parameter IN_W = 23,
    parameter PIXEL_W = 8
) (
    input  signed [IN_W-1:0] value_in,
    output [PIXEL_W-1:0] pixel_out
);

  localparam [PIXEL_W-1:0] MAX_PIXEL = {PIXEL_W{1'b1}};

  generate
    if (IN_W > PIXEL_W) begin : gen_wide_input
      wire is_negative = value_in[IN_W-1];
      wire too_large   = |value_in[IN_W-1:PIXEL_W];

      assign pixel_out = is_negative ? {PIXEL_W{1'b0}} :
                         too_large   ? MAX_PIXEL :
                                       value_in[PIXEL_W-1:0];
    end else begin : gen_narrow_input
      assign pixel_out = value_in[IN_W-1] ? {PIXEL_W{1'b0}} :
                                           {{(PIXEL_W-IN_W){1'b0}}, value_in};
    end
  endgenerate

endmodule