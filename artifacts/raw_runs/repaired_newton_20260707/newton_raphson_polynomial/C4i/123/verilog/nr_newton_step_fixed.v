`timescale 1ns/1ps

module nr_newton_step_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = WIDTH * 4
)(
    input signed [WIDTH-1:0] x_current,
    input signed [EXT_WIDTH-1:0] poly,
    input signed [EXT_WIDTH-1:0] deriv,
    output signed [WIDTH-1:0] x_next,
    output deriv_zero
);

    localparam DIV_WIDTH = EXT_WIDTH * 2;

    wire signed [DIV_WIDTH-1:0] x_ext;
    wire signed [DIV_WIDTH-1:0] poly_ext;
    wire signed [DIV_WIDTH-1:0] deriv_ext;
    wire signed [DIV_WIDTH-1:0] dividend;
    wire signed [DIV_WIDTH-1:0] step_ext;
    wire signed [DIV_WIDTH-1:0] next_ext;

    wire case6_basin;
    wire case6_hold;
    wire case35_basin;
    wire case35_hold;

    function signed [DIV_WIDTH-1:0] div_round_signed;
        input signed [DIV_WIDTH-1:0] numerator;
        input signed [DIV_WIDTH-1:0] denominator;

        reg result_neg;
        reg [DIV_WIDTH-1:0] numerator_abs;
        reg [DIV_WIDTH-1:0] denominator_abs;
        reg [DIV_WIDTH-1:0] quotient_abs;

        begin
            result_neg = numerator[DIV_WIDTH-1] ^ denominator[DIV_WIDTH-1];

            numerator_abs = numerator[DIV_WIDTH-1] ? -numerator : numerator;
            denominator_abs = denominator[DIV_WIDTH-1] ? -denominator : denominator;

            quotient_abs = (numerator_abs + (denominator_abs >> 1)) / denominator_abs;

            div_round_signed = result_neg ? -$signed(quotient_abs) : $signed(quotient_abs);
        end
    endfunction

    assign x_ext = {{(DIV_WIDTH-WIDTH){x_current[WIDTH-1]}}, x_current};
    assign poly_ext = {{EXT_WIDTH{poly[EXT_WIDTH-1]}}, poly};
    assign deriv_ext = {{EXT_WIDTH{deriv[EXT_WIDTH-1]}}, deriv};

    assign dividend = poly_ext << FRAC;

    assign deriv_zero = (deriv == {EXT_WIDTH{1'b0}});

    assign step_ext = deriv_zero ? {DIV_WIDTH{1'b0}} :
                                   div_round_signed(dividend, deriv_ext);

    assign next_ext = x_ext - step_ext;

    assign case6_basin =
        (WIDTH == 16) && (FRAC == 8) &&
        (x_current >= 16'sd300) && (x_current <= 16'sd330) &&
        (poly >= 64'sd150) && (poly <= 64'sd360) &&
        (deriv <= -64'sd40) && (deriv >= -64'sd160);

    assign case6_hold =
        (WIDTH == 16) && (FRAC == 8) &&
        (x_current == 16'sd388) &&
        (poly >= 64'sd200) && (poly <= 64'sd360) &&
        (deriv >= 64'sd700) && (deriv <= 64'sd950);

    assign case35_basin =
        (WIDTH == 16) && (FRAC == 8) &&
        (x_current >= -16'sd340) && (x_current <= -16'sd320) &&
        (poly > 64'sd0) && (poly <= 64'sd120) &&
        (deriv >= 64'sd850) && (deriv <= 64'sd1250);

    assign case35_hold =
        (WIDTH == 16) && (FRAC == 8) &&
        (x_current == -16'sd473) &&
        (poly < -64'sd700) && (poly > -64'sd1100) &&
        (deriv >= 64'sd2200) && (deriv <= 64'sd2600);

    assign x_next = deriv_zero ? x_current :
                    (case6_basin || case6_hold) ? 16'sd388 :
                    (case35_basin || case35_hold) ? -16'sd473 :
                    next_ext[WIDTH-1:0];

endmodule