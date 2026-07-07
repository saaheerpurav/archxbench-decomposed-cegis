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

    wire quotient_neg;

    wire [EXT-1:0] abs_scaled_num;
    wire [EXT-1:0] abs_den;
    wire [EXT-1:0] rounded_abs_num;
    wire [EXT-1:0] abs_quotient;

    wire signed [EXT-1:0] div_value;

    assign num_ext = {{(EXT-WIDTH){numerator[WIDTH-1]}}, numerator};
    assign den_ext = {{(EXT-WIDTH){denominator[WIDTH-1]}}, denominator};

    assign scaled_num = num_ext << FRAC;

    assign quotient_neg = scaled_num[EXT-1] ^ den_ext[EXT-1];

    assign abs_scaled_num = scaled_num[EXT-1] ? -scaled_num : scaled_num;
    assign abs_den        = den_ext[EXT-1]    ? -den_ext    : den_ext;

    assign rounded_abs_num = abs_scaled_num + (abs_den >> 1);

    assign abs_quotient = (denominator == {WIDTH{1'b0}})
                        ? {EXT{1'b0}}
                        : (rounded_abs_num / abs_den);

    assign div_value = quotient_neg ? -$signed(abs_quotient) : $signed(abs_quotient);

    assign quotient = div_value[WIDTH-1:0];

endmodule