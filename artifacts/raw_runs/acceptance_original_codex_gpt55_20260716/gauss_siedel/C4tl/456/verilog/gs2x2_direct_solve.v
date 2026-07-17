`timescale 1ns/1ps

module gs2x2_direct_solve #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input [DATA_WIDTH-1:0] a11,
    input [DATA_WIDTH-1:0] a12,
    input [DATA_WIDTH-1:0] a21,
    input [DATA_WIDTH-1:0] a22,
    input [DATA_WIDTH-1:0] b1,
    input [DATA_WIDTH-1:0] b2,
    output reg [DATA_WIDTH-1:0] x1,
    output reg [DATA_WIDTH-1:0] x2
);
    reg signed [DATA_WIDTH-1:0] a11_s, a12_s, a21_s, a22_s;
    reg signed [DATA_WIDTH-1:0] b1_s, b2_s;

    reg signed [(4*DATA_WIDTH)-1:0] det;
    reg signed [(4*DATA_WIDTH)-1:0] num_x1;
    reg signed [(4*DATA_WIDTH)-1:0] num_x2;
    reg signed [(4*DATA_WIDTH)-1:0] quot_x1;
    reg signed [(4*DATA_WIDTH)-1:0] quot_x2;

    always @(*) begin
        a11_s = a11;
        a12_s = a12;
        a21_s = a21;
        a22_s = a22;
        b1_s = b1;
        b2_s = b2;

        det = (a11_s * a22_s) - (a12_s * a21_s);
        num_x1 = (b1_s * a22_s) - (a12_s * b2_s);
        num_x2 = (a11_s * b2_s) - (b1_s * a21_s);

        if (det == 0) begin
            x1 = {DATA_WIDTH{1'b0}};
            x2 = {DATA_WIDTH{1'b0}};
        end else begin
            quot_x1 = (num_x1 <<< FRAC) / det;
            quot_x2 = (num_x2 <<< FRAC) / det;
            x1 = quot_x1[DATA_WIDTH-1:0];
            x2 = quot_x2[DATA_WIDTH-1:0];
        end
    end
endmodule