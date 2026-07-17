`timescale 1ns/1ps

module dct8_saturate #(
    parameter IN_W  = 32,
    parameter OUT_W = 18
) (
    input  signed [IN_W-1:0]      in_value,
    output reg signed [OUT_W-1:0] out_value
);

  localparam signed [OUT_W-1:0] OUT_MAX = {1'b0, {(OUT_W-1){1'b1}}};
  localparam signed [OUT_W-1:0] OUT_MIN = {1'b1, {(OUT_W-1){1'b0}}};

  localparam signed [IN_W-1:0] MAX_OUT = {{(IN_W-OUT_W){1'b0}}, OUT_MAX};
  localparam signed [IN_W-1:0] MIN_OUT = {{(IN_W-OUT_W){1'b1}}, OUT_MIN};

  always @* begin
    if (in_value > MAX_OUT) begin
      out_value = OUT_MAX;
    end else if (in_value < MIN_OUT) begin
      out_value = OUT_MIN;
    end else begin
      out_value = in_value[OUT_W-1:0];
    end
  end

endmodule