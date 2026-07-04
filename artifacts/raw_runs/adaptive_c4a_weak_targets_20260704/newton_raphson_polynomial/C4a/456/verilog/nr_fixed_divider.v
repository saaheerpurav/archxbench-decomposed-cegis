`timescale 1ns/1ps

module nr_fixed_divider #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] numerator,
    input  signed [WIDTH-1:0] denominator,
    output signed [WIDTH-1:0] quotient
);

    wire signed [(2*WIDTH)-1:0] numerator_ext;
    wire signed [(2*WIDTH)-1:0] scaled_numerator;
    wire signed [(2*WIDTH)-1:0] division_result;

    assign numerator_ext     = {{WIDTH{numerator[WIDTH-1]}}, numerator};
    assign scaled_numerator  = numerator_ext << FRAC;

    assign division_result = (denominator == {WIDTH{1'b0}})
                           ? {2*WIDTH{1'b0}}
                           : scaled_numerator / denominator;

    assign quotient = division_result[WIDTH-1:0];

endmodule