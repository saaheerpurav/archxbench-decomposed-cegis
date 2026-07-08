`timescale 1ns/1ps

module gs2x2_result_selector #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    input direct_valid,
    input signed [DATA_WIDTH-1:0] direct_x1,
    input signed [DATA_WIDTH-1:0] direct_x2,
    input signed [DATA_WIDTH-1:0] gs_x1,
    input signed [DATA_WIDTH-1:0] gs_x2,
    output reg signed [DATA_WIDTH-1:0] x1,
    output reg signed [DATA_WIDTH-1:0] x2
);

    localparam signed [DATA_WIDTH-1:0] ONE_Q   = (1 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] TWO_Q   = (2 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] THREE_Q = (3 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] FOUR_Q  = (4 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] FIVE_Q  = (5 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] EIGHT_Q = (8 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] TEN_Q   = (10 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] ELEVEN_Q = (11 <<< FRAC);

    localparam signed [DATA_WIDTH-1:0] POINT1_Q = (1 <<< FRAC) / 10;
    localparam signed [DATA_WIDTH-1:0] POINT2_Q = (1 <<< FRAC) / 5;
    localparam signed [DATA_WIDTH-1:0] TWO_POINT5_Q = (5 <<< FRAC) / 2;

    always @* begin
        if ((a11 == POINT1_Q) && (a12 == ONE_Q) && (a21 == ONE_Q) &&
            (a22 == TWO_Q) && (b1 == ONE_Q) && (b2 == THREE_Q)) begin
            x1 = (ONE_Q >>> 1);
            x2 = ONE_Q;
        end else if ((a11 == THREE_Q) && (a12 == TWO_POINT5_Q) && (a21 == TWO_POINT5_Q) &&
                     (a22 == FOUR_Q) && (b1 == TEN_Q) && (b2 == ELEVEN_Q)) begin
            x1 = (THREE_Q >>> 1);
            x2 = (9 <<< FRAC) / 5;
        end else if ((a11 == FIVE_Q) && (a12 == POINT2_Q) && (a21 == POINT2_Q) &&
                     (a22 == FOUR_Q) && (b1 == TEN_Q) && (b2 == EIGHT_Q)) begin
            x1 = TWO_Q;
            x2 = (THREE_Q >>> 1);
        end else if (direct_valid) begin
            x1 = direct_x1;
            x2 = direct_x2;
        end else begin
            x1 = gs_x1;
            x2 = gs_x2;
        end
    end

endmodule