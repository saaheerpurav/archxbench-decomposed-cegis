`timescale 1ns/1ps

module nr_fixed_div #(
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] numerator,
    input signed [EXT_WIDTH-1:0] denominator,
    output signed [EXT_WIDTH-1:0] quotient,
    output divide_by_zero
);

    wire signed [(2*EXT_WIDTH)-1:0] scaled_num;
    wire signed [(2*EXT_WIDTH)-1:0] wide_quotient;

    assign divide_by_zero = (denominator == {EXT_WIDTH{1'b0}});
    assign scaled_num = {{EXT_WIDTH{numerator[EXT_WIDTH-1]}}, numerator} << FRAC;
    assign wide_quotient = divide_by_zero ? {(2*EXT_WIDTH){1'b0}} : (scaled_num / denominator);
    assign quotient = wide_quotient[EXT_WIDTH-1:0];

endmodule