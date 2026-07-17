`timescale 1ns/1ps

module fixed_point_divider #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] numerator,
    input  signed [WIDTH-1:0] denominator,
    output signed [WIDTH-1:0] quotient,
    output divide_by_zero
);
    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] num_ext;
    wire signed [EXT-1:0] den_ext;
    wire signed [EXT-1:0] shifted_num;
    wire signed [EXT-1:0] quotient_ext;

    assign num_ext = {{(EXT-WIDTH){numerator[WIDTH-1]}}, numerator};
    assign den_ext = {{(EXT-WIDTH){denominator[WIDTH-1]}}, denominator};

    assign shifted_num = num_ext << FRAC;

    assign divide_by_zero = (denominator == {WIDTH{1'b0}});

    assign quotient_ext = divide_by_zero ? {EXT{1'b0}} : (shifted_num / den_ext);

    assign quotient = quotient_ext[WIDTH-1:0];

endmodule