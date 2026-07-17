`timescale 1ns/1ps

module gs_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] value,
    output reg signed [DATA_WIDTH-1:0] reciprocal
);
    reg signed [(2*DATA_WIDTH)-1:0] numerator;

    always @(*) begin
        if (value == 0) begin
            reciprocal = {DATA_WIDTH{1'b0}};
        end else begin
            numerator = {{(2*DATA_WIDTH-1){1'b0}}, 1'b1} <<< (2*FRAC);
            reciprocal = numerator / value;
        end
    end

endmodule