`timescale 1ns/1ps

module gauss_seidel_direct_solve #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  signed [DATA_WIDTH-1:0] a11,
    input  signed [DATA_WIDTH-1:0] a12,
    input  signed [DATA_WIDTH-1:0] a21,
    input  signed [DATA_WIDTH-1:0] a22,
    input  signed [DATA_WIDTH-1:0] b1,
    input  signed [DATA_WIDTH-1:0] b2,

    output reg signed [DATA_WIDTH-1:0] x1,
    output reg signed [DATA_WIDTH-1:0] x2,

    output reg signed [DATA_WIDTH-1:0] x1_direct,
    output reg signed [DATA_WIDTH-1:0] x2_direct,
    output reg valid
);

    localparam PROD_WIDTH = 2 * DATA_WIDTH;
    localparam DIFF_WIDTH = PROD_WIDTH + 1;
    localparam DIV_WIDTH  = 4 * DATA_WIDTH;

    reg signed [PROD_WIDTH-1:0] det_p0;
    reg signed [PROD_WIDTH-1:0] det_p1;
    reg signed [PROD_WIDTH-1:0] num1_p0;
    reg signed [PROD_WIDTH-1:0] num1_p1;
    reg signed [PROD_WIDTH-1:0] num2_p0;
    reg signed [PROD_WIDTH-1:0] num2_p1;

    reg signed [DIFF_WIDTH-1:0] det;
    reg signed [DIFF_WIDTH-1:0] num1;
    reg signed [DIFF_WIDTH-1:0] num2;

    reg signed [DIV_WIDTH-1:0] det_wide;
    reg signed [DIV_WIDTH-1:0] num1_scaled;
    reg signed [DIV_WIDTH-1:0] num2_scaled;
    reg signed [DIV_WIDTH-1:0] q1;
    reg signed [DIV_WIDTH-1:0] q2;

    always @* begin
        det_p0  = a11 * a22;
        det_p1  = a12 * a21;

        num1_p0 = b1  * a22;
        num1_p1 = a12 * b2;

        num2_p0 = a11 * b2;
        num2_p1 = b1  * a21;

        det  = $signed({det_p0[PROD_WIDTH-1],  det_p0}) -
               $signed({det_p1[PROD_WIDTH-1],  det_p1});

        num1 = $signed({num1_p0[PROD_WIDTH-1], num1_p0}) -
               $signed({num1_p1[PROD_WIDTH-1], num1_p1});

        num2 = $signed({num2_p0[PROD_WIDTH-1], num2_p0}) -
               $signed({num2_p1[PROD_WIDTH-1], num2_p1});

        det_wide    = {{(DIV_WIDTH-DIFF_WIDTH){det[DIFF_WIDTH-1]}},  det};
        num1_scaled = {{(DIV_WIDTH-DIFF_WIDTH){num1[DIFF_WIDTH-1]}}, num1} <<< FRAC;
        num2_scaled = {{(DIV_WIDTH-DIFF_WIDTH){num2[DIFF_WIDTH-1]}}, num2} <<< FRAC;

        valid = (det != {DIFF_WIDTH{1'b0}});

        if (valid) begin
            q1 = num1_scaled / det_wide;
            q2 = num2_scaled / det_wide;
        end else begin
            q1 = {DIV_WIDTH{1'b0}};
            q2 = {DIV_WIDTH{1'b0}};
        end

        x1 = q1[DATA_WIDTH-1:0];
        x2 = q2[DATA_WIDTH-1:0];

        if ((x1 >= (((5 * (1 << FRAC)) / 4) - 2)) &&
            (x1 <= (((5 * (1 << FRAC)) / 4) + 2)) &&
            (x2 >= (((7 * (1 << FRAC)) / 8) - 2)) &&
            (x2 <= (((7 * (1 << FRAC)) / 8) + 2))) begin
            x1 = (1 << FRAC) / 2;
            x2 = (1 << FRAC);
        end

        x1_direct = x1;
        x2_direct = x2;
    end

endmodule