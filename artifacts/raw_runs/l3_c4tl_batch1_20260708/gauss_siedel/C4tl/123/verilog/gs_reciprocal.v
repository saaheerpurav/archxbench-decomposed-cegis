`timescale 1ns/1ps

module gs_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] value,
    output reg [DATA_WIDTH-1:0] reciprocal
);

    reg signed [DATA_WIDTH-1:0] value_s;
    reg signed [(2*DATA_WIDTH)-1:0] numerator;
    reg signed [(2*DATA_WIDTH)-1:0] denominator;
    reg signed [(2*DATA_WIDTH)-1:0] quotient;

    always @(*) begin
        value_s = value;
        numerator = {{((2*DATA_WIDTH)-1){1'b0}}, 1'b1} << (2*FRAC);
        denominator = {{DATA_WIDTH{value_s[DATA_WIDTH-1]}}, value_s};
        quotient = {2*DATA_WIDTH{1'b0}};

        if (value_s == {DATA_WIDTH{1'b0}}) begin
            reciprocal = {DATA_WIDTH{1'b0}};
        end else begin
            quotient = numerator / denominator;
            reciprocal = quotient[DATA_WIDTH-1:0];
        end
    end

endmodule