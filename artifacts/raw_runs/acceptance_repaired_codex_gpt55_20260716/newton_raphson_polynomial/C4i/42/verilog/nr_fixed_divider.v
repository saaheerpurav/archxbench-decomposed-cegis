`timescale 1ns/1ps

module nr_fixed_divider #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input signed [(2*WIDTH)+7:0] numerator,
    input signed [(2*WIDTH)+7:0] denominator,
    output signed [(2*WIDTH)+7:0] quotient,
    output div_by_zero
);

    localparam OUTW = (2*WIDTH) + 8;

    wire signed [(2*OUTW)-1:0] numerator_ext;
    wire signed [(2*OUTW)-1:0] scaled_num;

    wire result_neg;
    wire [(2*OUTW)-1:0] abs_scaled_num;
    wire [OUTW-1:0] abs_denominator;
    wire [(2*OUTW)-1:0] round_bias;
    wire [(2*OUTW)-1:0] rounded_abs_num;
    wire [(2*OUTW)-1:0] quotient_mag;
    wire signed [(2*OUTW)-1:0] quotient_ext;

    wire signed [(2*OUTW)-1:0] max_out_ext;
    wire signed [(2*OUTW)-1:0] min_out_ext;

    assign numerator_ext = {{OUTW{numerator[OUTW-1]}}, numerator};
    assign scaled_num = numerator_ext << FRAC;

    assign div_by_zero = (denominator == {OUTW{1'b0}});

    assign result_neg = scaled_num[(2*OUTW)-1] ^ denominator[OUTW-1];

    assign abs_scaled_num = scaled_num[(2*OUTW)-1] ? (~scaled_num + 1'b1) : scaled_num;
    assign abs_denominator = denominator[OUTW-1] ? (~denominator + 1'b1) : denominator;

    assign round_bias = {{OUTW{1'b0}}, (abs_denominator >> 1)};
    assign rounded_abs_num = abs_scaled_num + round_bias;

    assign quotient_mag = div_by_zero ? {(2*OUTW){1'b0}} :
                                        (rounded_abs_num / abs_denominator);

    assign quotient_ext = result_neg ? -$signed(quotient_mag) :
                                       $signed(quotient_mag);

    assign max_out_ext = {{OUTW{1'b0}}, 1'b0, {(OUTW-1){1'b1}}};
    assign min_out_ext = {{OUTW{1'b1}}, 1'b1, {(OUTW-1){1'b0}}};

    assign quotient = div_by_zero ? {OUTW{1'b0}} :
                      (quotient_ext > max_out_ext) ? {1'b0, {(OUTW-1){1'b1}}} :
                      (quotient_ext < min_out_ext) ? {1'b1, {(OUTW-1){1'b0}}} :
                      quotient_ext[OUTW-1:0];

endmodule