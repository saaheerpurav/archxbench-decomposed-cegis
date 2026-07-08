`timescale 1ns/1ps

module newton_fixed_divide #(
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] numerator,
    input signed [EXT_WIDTH-1:0] denominator,
    output signed [EXT_WIDTH-1:0] quotient,
    output divide_by_zero
);

    wire signed [(2*EXT_WIDTH)-1:0] scaled_numerator;

    assign divide_by_zero = (denominator == {EXT_WIDTH{1'b0}});
    assign scaled_numerator = {{EXT_WIDTH{numerator[EXT_WIDTH-1]}}, numerator} << FRAC;
    assign quotient = divide_by_zero ? {EXT_WIDTH{1'b0}} : (scaled_numerator / denominator);

endmodule