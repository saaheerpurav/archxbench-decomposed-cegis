`timescale 1ns/1ps

module gs2x2_signed_divider #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [(2*DATA_WIDTH)-1:0] numerator,
    input signed [(2*DATA_WIDTH)-1:0] denominator,
    output [DATA_WIDTH-1:0] quotient
);

    wire signed [(4*DATA_WIDTH)-1:0] scaled_num = numerator <<< FRAC;
    wire signed [(4*DATA_WIDTH)-1:0] wide_den = denominator;
    wire signed [(4*DATA_WIDTH)-1:0] wide_quotient =
        (denominator == 0) ? {4*DATA_WIDTH{1'b0}} : (scaled_num / wide_den);

    assign quotient = wide_quotient[DATA_WIDTH-1:0];

endmodule