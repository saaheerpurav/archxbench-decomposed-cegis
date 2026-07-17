`timescale 1ns/1ps

module gs2x2_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input [DATA_WIDTH-1:0] a,
    output reg [DATA_WIDTH-1:0] reciprocal
);
    reg signed [DATA_WIDTH-1:0] a_s;
    reg signed [(4*DATA_WIDTH)-1:0] numerator;
    reg signed [(4*DATA_WIDTH)-1:0] quotient;

    always @(*) begin
        a_s = a;
        numerator = {{((4*DATA_WIDTH)-1){1'b0}}, 1'b1} <<< (2*FRAC);

        if (a_s == 0) begin
            reciprocal = {DATA_WIDTH{1'b0}};
        end else begin
            quotient = numerator / a_s;
            reciprocal = quotient[DATA_WIDTH-1:0];
        end
    end
endmodule