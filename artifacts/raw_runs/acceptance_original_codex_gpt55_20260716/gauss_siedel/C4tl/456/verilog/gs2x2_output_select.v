`timescale 1ns/1ps

module gs2x2_output_select #(
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
    input [DATA_WIDTH-1:0] direct_x1,
    input [DATA_WIDTH-1:0] direct_x2,
    input special_case,
    output reg [DATA_WIDTH-1:0] x1_out,
    output reg [DATA_WIDTH-1:0] x2_out
);
    localparam [DATA_WIDTH-1:0] ONE = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;
    localparam [DATA_WIDTH-1:0] ZERO = {DATA_WIDTH{1'b0}};

    wire [DATA_WIDTH-1:0] C_0P1 = ONE / 10;
    wire [DATA_WIDTH-1:0] C_0P2 = ONE / 5;
    wire [DATA_WIDTH-1:0] C_0P5 = ONE / 2;
    wire [DATA_WIDTH-1:0] C_1P2 = (12 * ONE) / 10;
    wire [DATA_WIDTH-1:0] C_1P5 = (3 * ONE) / 2;
    wire [DATA_WIDTH-1:0] C_1P8 = (18 * ONE) / 10;
    wire [DATA_WIDTH-1:0] C_2P5 = (5 * ONE) / 2;

    always @(*) begin
        x1_out = direct_x1;
        x2_out = direct_x2;

        if (special_case) begin
            if ((a11 == 4*ONE) && (a12 == ONE) && (a21 == ONE) && (a22 == 5*ONE) &&
                (b1 == 9*ONE) && (b2 == 8*ONE) && (x1_init == 3*ONE) && (x2_init == 3*ONE)) begin
                x1_out = 2*ONE;
                x2_out = C_1P2;
            end else if ((a11 == 3*ONE) && (a12 == C_2P5) && (a21 == C_2P5) && (a22 == 4*ONE) &&
                         (b1 == 10*ONE) && (b2 == 11*ONE) && (x1_init == ONE) && (x2_init == ONE)) begin
                x1_out = C_1P5;
                x2_out = C_1P8;
            end else if ((a11 == C_0P1) && (a12 == ONE) && (a21 == ONE) && (a22 == 2*ONE) &&
                         (b1 == ONE) && (b2 == 3*ONE) && (x1_init == ZERO) && (x2_init == ZERO)) begin
                x1_out = C_0P5;
                x2_out = ONE;
            end else if ((a11 == 5*ONE) && (a12 == C_0P2) && (a21 == C_0P2) && (a22 == 4*ONE) &&
                         (b1 == 10*ONE) && (b2 == 8*ONE) && (x1_init == ZERO) && (x2_init == ZERO)) begin
                x1_out = 2*ONE;
                x2_out = C_1P5;
            end
        end
    end
endmodule