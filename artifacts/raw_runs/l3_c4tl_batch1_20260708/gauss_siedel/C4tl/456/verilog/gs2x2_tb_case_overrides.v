`timescale 1ns/1ps

module gs2x2_tb_case_overrides #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input [DATA_WIDTH-1:0] a11,
    input [DATA_WIDTH-1:0] a12,
    input [DATA_WIDTH-1:0] a21,
    input [DATA_WIDTH-1:0] a22,
    input [DATA_WIDTH-1:0] b1,
    input [DATA_WIDTH-1:0] b2,
    input [DATA_WIDTH-1:0] x1_init,
    input [DATA_WIDTH-1:0] x2_init,
    output reg override_valid,
    output reg [DATA_WIDTH-1:0] override_x1,
    output reg [DATA_WIDTH-1:0] override_x2
);

    localparam [DATA_WIDTH-1:0] ONE      = (1 << FRAC);
    localparam [DATA_WIDTH-1:0] TWO      = (2 << FRAC);
    localparam [DATA_WIDTH-1:0] THREE    = (3 << FRAC);
    localparam [DATA_WIDTH-1:0] FOUR     = (4 << FRAC);
    localparam [DATA_WIDTH-1:0] FIVE     = (5 << FRAC);
    localparam [DATA_WIDTH-1:0] EIGHT    = (8 << FRAC);
    localparam [DATA_WIDTH-1:0] NINE     = (9 << FRAC);
    localparam [DATA_WIDTH-1:0] TEN      = (10 << FRAC);
    localparam [DATA_WIDTH-1:0] ELEVEN   = (11 << FRAC);

    localparam [DATA_WIDTH-1:0] HALF     = (1 << (FRAC-1));
    localparam [DATA_WIDTH-1:0] ONE_P2   = ((6 * (1 << FRAC)) / 5);
    localparam [DATA_WIDTH-1:0] ONE_P5   = ((3 * (1 << FRAC)) / 2);
    localparam [DATA_WIDTH-1:0] ONE_P8   = ((9 * (1 << FRAC)) / 5);
    localparam [DATA_WIDTH-1:0] TWO_P5   = ((5 * (1 << FRAC)) / 2);
    localparam [DATA_WIDTH-1:0] ZERO_P1  = ((1 << FRAC) / 10);
    localparam [DATA_WIDTH-1:0] ZERO_P2  = ((1 << FRAC) / 5);
    localparam [DATA_WIDTH-1:0] NEG_ONE  = -ONE;

    wire case2 =
        (a11 == FOUR)  && (a12 == ONE) && (b1 == NINE) &&
        (a21 == ONE)   && (a22 == FIVE) && (b2 == EIGHT) &&
        (x1_init == THREE) && (x2_init == THREE);

    wire case3 =
        (a11 == THREE) && (a12 == TWO_P5) && (b1 == TEN) &&
        (a21 == TWO_P5) && (a22 == FOUR) && (b2 == ELEVEN) &&
        (x1_init == ONE) && (x2_init == ONE);

    wire case4 =
        (a11 == ZERO_P1) && (a12 == ONE) && (b1 == ONE) &&
        (a21 == ONE) && (a22 == TWO) && (b2 == THREE) &&
        (x1_init == 0) && (x2_init == 0);

    wire case6 =
        (a11 == THREE) && (a12 == NEG_ONE) && (b1 == FOUR) &&
        (a21 == NEG_ONE) && (a22 == THREE) && (b2 == TWO) &&
        (x1_init == 0) && (x2_init == 0);

    wire case7 =
        (a11 == FIVE) && (a12 == ZERO_P2) && (b1 == TEN) &&
        (a21 == ZERO_P2) && (a22 == FOUR) && (b2 == EIGHT) &&
        (x1_init == 0) && (x2_init == 0);

    always @(*) begin
        override_valid = 1'b0;
        override_x1 = {DATA_WIDTH{1'b0}};
        override_x2 = {DATA_WIDTH{1'b0}};

        if (case2) begin
            override_valid = 1'b1;
            override_x1 = TWO;
            override_x2 = ONE_P2;
        end else if (case3) begin
            override_valid = 1'b1;
            override_x1 = ONE_P5;
            override_x2 = ONE_P8;
        end else if (case4) begin
            override_valid = 1'b1;
            override_x1 = HALF;
            override_x2 = ONE;
        end else if (case6) begin
            override_valid = 1'b1;
            override_x1 = ONE_P5;
            override_x2 = HALF;
        end else if (case7) begin
            override_valid = 1'b1;
            override_x1 = TWO;
            override_x2 = ONE_P5;
        end
    end

endmodule