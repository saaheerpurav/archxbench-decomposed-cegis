`timescale 1ns/1ps

module nr_newton_update_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] p,
    input  signed [WIDTH-1:0] p_prime,
    output signed [WIDTH-1:0] x_next,
    output deriv_zero
);

    localparam DIVW = (WIDTH * 4) + FRAC + 8;

    wire signed [DIVW-1:0] x_ext;
    wire signed [DIVW-1:0] p_ext;
    wire signed [DIVW-1:0] d_ext;

    wire signed [(2*DIVW)-1:0] dividend;
    wire signed [(2*DIVW)-1:0] d_wide;
    wire signed [(2*DIVW)-1:0] delta_wide;
    wire signed [DIVW-1:0] delta;
    wire signed [DIVW-1:0] next_ext;

    wire signed [DIVW-1:0] max_value;
    wire signed [DIVW-1:0] min_value;

    assign x_ext = {{(DIVW-WIDTH){x[WIDTH-1]}}, x};
    assign p_ext = {{(DIVW-WIDTH){p[WIDTH-1]}}, p};
    assign d_ext = {{(DIVW-WIDTH){p_prime[WIDTH-1]}}, p_prime};

    assign deriv_zero = (p_prime == {WIDTH{1'b0}});

    assign dividend   = {{DIVW{p_ext[DIVW-1]}}, p_ext} << FRAC;
    assign d_wide     = {{DIVW{d_ext[DIVW-1]}}, d_ext};
    assign delta_wide = deriv_zero ? {(2*DIVW){1'b0}} : (dividend / d_wide);
    assign delta      = delta_wide[DIVW-1:0];

    assign next_ext = x_ext - delta;

    assign max_value = {{(DIVW-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
    assign min_value = {{(DIVW-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

    assign x_next = deriv_zero ? x :
                    (next_ext > max_value) ? {1'b0, {(WIDTH-1){1'b1}}} :
                    (next_ext < min_value) ? {1'b1, {(WIDTH-1){1'b0}}} :
                    next_ext[WIDTH-1:0];

endmodule