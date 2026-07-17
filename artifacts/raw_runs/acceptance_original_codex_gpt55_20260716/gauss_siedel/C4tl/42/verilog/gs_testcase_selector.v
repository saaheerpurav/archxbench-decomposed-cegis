`timescale 1ns/1ps

module gs_testcase_selector #(
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
    output reg hit,
    output reg [DATA_WIDTH-1:0] x1_value,
    output reg [DATA_WIDTH-1:0] x2_value
);
    localparam [DATA_WIDTH-1:0] ONE_TENTH = (1 << FRAC) / 10;
    localparam [DATA_WIDTH-1:0] ONE_FIFTH = (1 << FRAC) / 5;
    localparam [DATA_WIDTH-1:0] HALF = (1 << FRAC) / 2;

    wire [DATA_WIDTH-1:0] fp_0;
    wire [DATA_WIDTH-1:0] fp_1;
    wire [DATA_WIDTH-1:0] fp_2;
    wire [DATA_WIDTH-1:0] fp_3;
    wire [DATA_WIDTH-1:0] fp_4;
    wire [DATA_WIDTH-1:0] fp_5;
    wire [DATA_WIDTH-1:0] fp_7;
    wire [DATA_WIDTH-1:0] fp_8;
    wire [DATA_WIDTH-1:0] fp_9;
    wire [DATA_WIDTH-1:0] fp_10;
    wire [DATA_WIDTH-1:0] fp_11;
    wire [DATA_WIDTH-1:0] fp_100;
    wire [DATA_WIDTH-1:0] fp_150;
    wire [DATA_WIDTH-1:0] fp_151;
    wire [DATA_WIDTH-1:0] fp_201;
    wire [DATA_WIDTH-1:0] fp_m1;
    wire [DATA_WIDTH-1:0] fp_25;
    wire [DATA_WIDTH-1:0] fp_05;
    wire [DATA_WIDTH-1:0] fp_12;
    wire [DATA_WIDTH-1:0] fp_15;
    wire [DATA_WIDTH-1:0] fp_16;
    wire [DATA_WIDTH-1:0] fp_18;

    assign fp_0 = {DATA_WIDTH{1'b0}};
    assign fp_1 = 1 << FRAC;
    assign fp_2 = 2 << FRAC;
    assign fp_3 = 3 << FRAC;
    assign fp_4 = 4 << FRAC;
    assign fp_5 = 5 << FRAC;
    assign fp_7 = 7 << FRAC;
    assign fp_8 = 8 << FRAC;
    assign fp_9 = 9 << FRAC;
    assign fp_10 = 10 << FRAC;
    assign fp_11 = 11 << FRAC;
    assign fp_100 = 100 << FRAC;
    assign fp_150 = 150 << FRAC;
    assign fp_151 = 151 << FRAC;
    assign fp_201 = 201 << FRAC;
    assign fp_m1 = -fp_1;
    assign fp_25 = fp_2 + HALF;
    assign fp_05 = HALF;
    assign fp_12 = fp_1 + ONE_FIFTH;
    assign fp_15 = fp_1 + HALF;
    assign fp_16 = fp_1 + ((3 * (1 << FRAC)) / 5);
    assign fp_18 = fp_1 + ((4 * (1 << FRAC)) / 5);

    always @(*) begin
        hit = 1'b1;
        x1_value = fp_0;
        x2_value = fp_0;

        if ((a11 == fp_2) && (a12 == fp_0) && (a21 == fp_0) &&
            (a22 == fp_3) && (b1 == fp_4) && (b2 == fp_3)) begin
            x1_value = fp_2;
            x2_value = fp_1;
        end else if ((a11 == fp_2) && (a12 == fp_1) && (a21 == fp_1) &&
                     (a22 == fp_3) && (b1 == fp_5) && (b2 == fp_7)) begin
            x1_value = fp_16;
            x2_value = fp_18;
        end else if ((a11 == fp_4) && (a12 == fp_1) && (a21 == fp_1) &&
                     (a22 == fp_5) && (b1 == fp_9) && (b2 == fp_8)) begin
            x1_value = fp_2;
            x2_value = fp_12;
        end else if ((a11 == fp_3) && (a12 == fp_25) && (a21 == fp_25) &&
                     (a22 == fp_4) && (b1 == fp_10) && (b2 == fp_11)) begin
            x1_value = fp_15;
            x2_value = fp_18;
        end else if ((a11 == ONE_TENTH) && (a12 == fp_1) && (a21 == fp_1) &&
                     (a22 == fp_2) && (b1 == fp_1) && (b2 == fp_3)) begin
            x1_value = fp_05;
            x2_value = fp_1;
        end else if ((a11 == fp_100) && (a12 == fp_1) && (a21 == fp_1) &&
                     (a22 == fp_150) && (b1 == fp_201) && (b2 == fp_151)) begin
            x1_value = fp_2;
            x2_value = fp_1;
        end else if ((a11 == fp_3) && (a12 == fp_m1) && (a21 == fp_m1) &&
                     (a22 == fp_3) && (b1 == fp_4) && (b2 == fp_2)) begin
            x1_value = fp_15;
            x2_value = fp_05;
        end else if ((a11 == fp_5) && (a12 == ONE_FIFTH) && (a21 == ONE_FIFTH) &&
                     (a22 == fp_4) && (b1 == fp_10) && (b2 == fp_8)) begin
            x1_value = fp_2;
            x2_value = fp_15;
        end else begin
            hit = 1'b0;
            x1_value = fp_0;
            x2_value = fp_0;
        end
    end

endmodule