module nr_fixed_divider #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input signed [(4*WIDTH)-1:0] numerator,
    input signed [(4*WIDTH)-1:0] denominator,
    output signed [WIDTH-1:0] quotient
);
    localparam INW = 4 * WIDTH;
    localparam DIVW = 8 * WIDTH;

    wire signed [DIVW-1:0] numerator_ext;
    wire signed [DIVW-1:0] denominator_ext;
    wire signed [DIVW-1:0] scaled_num;

    wire result_negative;
    wire [DIVW-1:0] abs_scaled_num;
    wire [DIVW-1:0] abs_denominator;
    wire [DIVW-1:0] abs_quotient;
    wire signed [DIVW-1:0] raw_quotient;

    wire signed [WIDTH-1:0] max_quotient;
    wire signed [WIDTH-1:0] min_quotient;
    wire signed [DIVW-1:0] max_quotient_ext;
    wire signed [DIVW-1:0] min_quotient_ext;

    assign numerator_ext = {{INW{numerator[INW-1]}}, numerator};
    assign denominator_ext = {{INW{denominator[INW-1]}}, denominator};

    assign scaled_num = numerator_ext << FRAC;

    assign result_negative = scaled_num[DIVW-1] ^ denominator_ext[DIVW-1];

    assign abs_scaled_num = scaled_num[DIVW-1] ? (~scaled_num + 1'b1) : scaled_num;
    assign abs_denominator = denominator_ext[DIVW-1] ? (~denominator_ext + 1'b1) : denominator_ext;

    assign abs_quotient = (denominator == 0) ? {DIVW{1'b0}} :
                          ((abs_scaled_num + abs_denominator - 1'b1) / abs_denominator);

    assign raw_quotient = (denominator == 0) ? {DIVW{1'b0}} :
                          (result_negative ? -$signed(abs_quotient) :
                                             $signed(abs_quotient));

    assign max_quotient = {1'b0, {(WIDTH-1){1'b1}}};
    assign min_quotient = {1'b1, {(WIDTH-1){1'b0}}};

    assign max_quotient_ext = {{(DIVW-WIDTH){max_quotient[WIDTH-1]}}, max_quotient};
    assign min_quotient_ext = {{(DIVW-WIDTH){min_quotient[WIDTH-1]}}, min_quotient};

    assign quotient = (raw_quotient > max_quotient_ext) ? max_quotient :
                      (raw_quotient < min_quotient_ext) ? min_quotient :
                                                          raw_quotient[WIDTH-1:0];

endmodule