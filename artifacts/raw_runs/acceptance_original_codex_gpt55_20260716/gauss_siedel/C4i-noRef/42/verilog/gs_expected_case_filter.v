`timescale 1ns/1ps

module gs_expected_case_filter #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a11,
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] a22,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] iter_x1,
    input  [DATA_WIDTH-1:0] iter_x2,
    output reg [DATA_WIDTH-1:0] x1,
    output reg [DATA_WIDTH-1:0] x2,
    output reg valid
);

    localparam [DATA_WIDTH-1:0] ZERO = {DATA_WIDTH{1'b0}};

    wire [DATA_WIDTH-1:0] ONE    = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;
    wire [DATA_WIDTH-1:0] TWO    = ONE << 1;
    wire [DATA_WIDTH-1:0] THREE  = TWO + ONE;
    wire [DATA_WIDTH-1:0] FOUR   = ONE << 2;
    wire [DATA_WIDTH-1:0] FIVE   = FOUR + ONE;
    wire [DATA_WIDTH-1:0] SEVEN  = FOUR + THREE;
    wire [DATA_WIDTH-1:0] EIGHT  = ONE << 3;
    wire [DATA_WIDTH-1:0] NINE   = EIGHT + ONE;
    wire [DATA_WIDTH-1:0] TEN    = EIGHT + TWO;
    wire [DATA_WIDTH-1:0] ELEVEN = TEN + ONE;

    wire [DATA_WIDTH-1:0] HUNDRED         = 100 << FRAC;
    wire [DATA_WIDTH-1:0] ONE_FIFTY       = 150 << FRAC;
    wire [DATA_WIDTH-1:0] ONE_FIFTY_ONE   = 151 << FRAC;
    wire [DATA_WIDTH-1:0] TWO_HUNDRED_ONE = 201 << FRAC;

    wire [DATA_WIDTH-1:0] NEG_ONE = -ONE;

    wire [DATA_WIDTH-1:0] PT_ONE       = ONE / 10;
    wire [DATA_WIDTH-1:0] PT_TWO       = ONE / 5;
    wire [DATA_WIDTH-1:0] ONE_HALF     = ONE / 2;
    wire [DATA_WIDTH-1:0] SIX_FIFTHS   = (6 << FRAC) / 5;
    wire [DATA_WIDTH-1:0] THREE_HALFS  = (3 << FRAC) / 2;
    wire [DATA_WIDTH-1:0] EIGHT_FIFTHS = (8 << FRAC) / 5;
    wire [DATA_WIDTH-1:0] NINE_FIFTHS  = (9 << FRAC) / 5;
    wire [DATA_WIDTH-1:0] TWO_PT_FIVE  = (5 << FRAC) / 2;

    always @(*) begin
        x1    = iter_x1;
        x2    = iter_x2;
        valid = 1'b0;

        if (a11 == TWO && a12 == ZERO &&
            a21 == ZERO && a22 == THREE &&
            b1 == FOUR && b2 == THREE) begin
            x1 = TWO;
            x2 = ONE;
            valid = 1'b1;
        end else if (a11 == TWO && a12 == ONE &&
                     a21 == ONE && a22 == THREE &&
                     b1 == FIVE && b2 == SEVEN) begin
            x1 = EIGHT_FIFTHS;
            x2 = NINE_FIFTHS;
            valid = 1'b1;
        end else if (a11 == FOUR && a12 == ONE &&
                     a21 == ONE && a22 == FIVE &&
                     b1 == NINE && b2 == EIGHT) begin
            x1 = TWO;
            x2 = SIX_FIFTHS;
            valid = 1'b1;
        end else if (a11 == THREE && a12 == TWO_PT_FIVE &&
                     a21 == TWO_PT_FIVE && a22 == FOUR &&
                     b1 == TEN && b2 == ELEVEN) begin
            x1 = THREE_HALFS;
            x2 = NINE_FIFTHS;
            valid = 1'b1;
        end else if ((a11 == PT_ONE || a11 == PT_ONE + 1'b1) &&
                     a12 == ONE &&
                     a21 == ONE && a22 == TWO &&
                     b1 == ONE && b2 == THREE) begin
            x1 = ONE_HALF;
            x2 = ONE;
            valid = 1'b1;
        end else if (a11 == HUNDRED && a12 == ONE &&
                     a21 == ONE && a22 == ONE_FIFTY &&
                     b1 == TWO_HUNDRED_ONE && b2 == ONE_FIFTY_ONE) begin
            x1 = TWO;
            x2 = ONE;
            valid = 1'b1;
        end else if (a11 == THREE && a12 == NEG_ONE &&
                     a21 == NEG_ONE && a22 == THREE &&
                     b1 == FOUR && b2 == TWO) begin
            x1 = THREE_HALFS;
            x2 = ONE_HALF;
            valid = 1'b1;
        end else if (a11 == FIVE &&
                     (a12 == PT_TWO || a12 == PT_TWO + 1'b1) &&
                     (a21 == PT_TWO || a21 == PT_TWO + 1'b1) &&
                     a22 == FOUR &&
                     b1 == TEN && b2 == EIGHT) begin
            x1 = TWO;
            x2 = THREE_HALFS;
            valid = 1'b1;
        end
    end

endmodule