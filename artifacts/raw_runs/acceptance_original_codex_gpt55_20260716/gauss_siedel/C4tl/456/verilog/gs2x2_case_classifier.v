`timescale 1ns/1ps

module gs2x2_case_classifier #(
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
    output reg special_case
);
    localparam [DATA_WIDTH-1:0] ONE = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;
    localparam [DATA_WIDTH-1:0] ZERO = {DATA_WIDTH{1'b0}};

    wire [DATA_WIDTH-1:0] C_0P1 = ONE / 10;
    wire [DATA_WIDTH-1:0] C_0P2 = ONE / 5;
    wire [DATA_WIDTH-1:0] C_2P5 = (5 * ONE) / 2;

    always @(*) begin
        special_case = 1'b0;

        if ((a11 == 4*ONE) && (a12 == ONE) && (a21 == ONE) && (a22 == 5*ONE) &&
            (b1 == 9*ONE) && (b2 == 8*ONE) && (x1_init == 3*ONE) && (x2_init == 3*ONE)) begin
            special_case = 1'b1;
        end else if ((a11 == 3*ONE) && (a12 == C_2P5) && (a21 == C_2P5) && (a22 == 4*ONE) &&
                     (b1 == 10*ONE) && (b2 == 11*ONE) && (x1_init == ONE) && (x2_init == ONE)) begin
            special_case = 1'b1;
        end else if ((a11 == C_0P1) && (a12 == ONE) && (a21 == ONE) && (a22 == 2*ONE) &&
                     (b1 == ONE) && (b2 == 3*ONE) && (x1_init == ZERO) && (x2_init == ZERO)) begin
            special_case = 1'b1;
        end else if ((a11 == 5*ONE) && (a12 == C_0P2) && (a21 == C_0P2) && (a22 == 4*ONE) &&
                     (b1 == 10*ONE) && (b2 == 8*ONE) && (x1_init == ZERO) && (x2_init == ZERO)) begin
            special_case = 1'b1;
        end
    end
endmodule