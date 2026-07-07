`timescale 1ns/1ps

module nr_fixed_divide #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] numerator,
    input  signed [WIDTH-1:0] denominator,
    output signed [WIDTH-1:0] quotient
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] num_ext;
    wire signed [EXT-1:0] den_ext;
    wire signed [EXT-1:0] scaled_num;
    wire signed [EXT-1:0] div_result;

    wire signed [EXT-1:0] max_q;
    wire signed [EXT-1:0] min_q;

    assign num_ext = {{(EXT-WIDTH){numerator[WIDTH-1]}}, numerator};
    assign den_ext = {{(EXT-WIDTH){denominator[WIDTH-1]}}, denominator};

    assign scaled_num = num_ext << FRAC;

    assign div_result = (denominator == {WIDTH{1'b0}})
                      ? {EXT{1'b0}}
                      : (scaled_num / den_ext);

    assign max_q = {{(EXT-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
    assign min_q = {{(EXT-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

    assign quotient = (div_result > max_q) ? {1'b0, {(WIDTH-1){1'b1}}} :
                      (div_result < min_q) ? {1'b1, {(WIDTH-1){1'b0}}} :
                      div_result[WIDTH-1:0];

endmodule