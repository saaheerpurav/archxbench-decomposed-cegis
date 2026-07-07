`timescale 1ns/1ps

module nr_fixed_div #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [(4*WIDTH)-1:0] numerator,
    input  signed [(4*WIDTH)-1:0] denominator,
    output signed [WIDTH-1:0] quotient,
    output divide_by_zero
);

    localparam EXT  = 4 * WIDTH;
    localparam DIVW = 8 * WIDTH;

    wire signed [DIVW-1:0] numerator_ext;
    wire signed [DIVW-1:0] denominator_ext;
    wire signed [DIVW-1:0] scaled_numerator;
    wire signed [DIVW-1:0] quotient_ext;

    assign divide_by_zero = (denominator == {EXT{1'b0}});

    assign numerator_ext   = {{(DIVW-EXT){numerator[EXT-1]}}, numerator};
    assign denominator_ext = {{(DIVW-EXT){denominator[EXT-1]}}, denominator};

    assign scaled_numerator = numerator_ext << FRAC;

    assign quotient_ext = divide_by_zero
                        ? {DIVW{1'b0}}
                        : (scaled_numerator / denominator_ext);

    assign quotient = quotient_ext[WIDTH-1:0];

endmodule