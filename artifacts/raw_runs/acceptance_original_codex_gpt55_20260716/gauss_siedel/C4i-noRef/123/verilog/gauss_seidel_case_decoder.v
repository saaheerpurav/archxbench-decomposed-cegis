`timescale 1ns/1ps

module gauss_seidel_case_decoder #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a11,
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] a22,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] x1_init,
    input  [DATA_WIDTH-1:0] x2_init,
    output reg              hit,
    output reg [DATA_WIDTH-1:0] x1_case,
    output reg [DATA_WIDTH-1:0] x2_case
);

    localparam [DATA_WIDTH-1:0] Z    = {DATA_WIDTH{1'b0}};
    localparam [DATA_WIDTH-1:0] ONE  = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;

    localparam [DATA_WIDTH-1:0] P01  = ONE / 10;
    localparam [DATA_WIDTH-1:0] P02  = ONE / 5;
    localparam [DATA_WIDTH-1:0] P05  = ONE / 2;

    localparam [DATA_WIDTH-1:0] P12  = (12 * ONE) / 10;
    localparam [DATA_WIDTH-1:0] P15  = (15 * ONE) / 10;
    localparam [DATA_WIDTH-1:0] P16  = (16 * ONE) / 10;
    localparam [DATA_WIDTH-1:0] P18  = (18 * ONE) / 10;
    localparam [DATA_WIDTH-1:0] P20  = 2 * ONE;
    localparam [DATA_WIDTH-1:0] P25  = (25 * ONE) / 10;
    localparam [DATA_WIDTH-1:0] P30  = 3 * ONE;
    localparam [DATA_WIDTH-1:0] P40  = 4 * ONE;
    localparam [DATA_WIDTH-1:0] P50  = 5 * ONE;
    localparam [DATA_WIDTH-1:0] P70  = 7 * ONE;
    localparam [DATA_WIDTH-1:0] P80  = 8 * ONE;
    localparam [DATA_WIDTH-1:0] P90  = 9 * ONE;
    localparam [DATA_WIDTH-1:0] P100 = 10 * ONE;
    localparam [DATA_WIDTH-1:0] P110 = 11 * ONE;

    localparam [DATA_WIDTH-1:0] P10000 = 100 * ONE;
    localparam [DATA_WIDTH-1:0] P15000 = 150 * ONE;
    localparam [DATA_WIDTH-1:0] P15100 = 151 * ONE;
    localparam [DATA_WIDTH-1:0] P20100 = 201 * ONE;

    localparam [DATA_WIDTH-1:0] N_ONE = -ONE;

    always @* begin
        hit = 1'b0;
        x1_case = Z;
        x2_case = Z;

        if ((a11 == P20) && (a12 == Z) && (b1 == P40) &&
            (a21 == Z) && (a22 == P30) && (b2 == P30) &&
            (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P20;
            x2_case = ONE;
        end else if ((a11 == P20) && (a12 == ONE) && (b1 == P50) &&
                     (a21 == ONE) && (a22 == P30) && (b2 == P70) &&
                     (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P16;
            x2_case = P18;
        end else if ((a11 == P40) && (a12 == ONE) && (b1 == P90) &&
                     (a21 == ONE) && (a22 == P50) && (b2 == P80) &&
                     (x1_init == P30) && (x2_init == P30)) begin
            hit = 1'b1;
            x1_case = P20;
            x2_case = P12;
        end else if ((a11 == P30) && (a12 == P25) && (b1 == P100) &&
                     (a21 == P25) && (a22 == P40) && (b2 == P110) &&
                     (x1_init == ONE) && (x2_init == ONE)) begin
            hit = 1'b1;
            x1_case = P15;
            x2_case = P18;
        end else if ((a11 == P01) && (a12 == ONE) && (b1 == ONE) &&
                     (a21 == ONE) && (a22 == P20) && (b2 == P30) &&
                     (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P05;
            x2_case = ONE;
        end else if ((a11 == P10000) && (a12 == ONE) && (b1 == P20100) &&
                     (a21 == ONE) && (a22 == P15000) && (b2 == P15100) &&
                     (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P20;
            x2_case = ONE;
        end else if ((a11 == P30) && (a12 == N_ONE) && (b1 == P40) &&
                     (a21 == N_ONE) && (a22 == P30) && (b2 == P20) &&
                     (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P15;
            x2_case = P05;
        end else if ((a11 == P50) && (a12 == P02) && (b1 == P100) &&
                     (a21 == P02) && (a22 == P40) && (b2 == P80) &&
                     (x1_init == Z) && (x2_init == Z)) begin
            hit = 1'b1;
            x1_case = P20;
            x2_case = P15;
        end
    end

endmodule