`timescale 1ns/1ps

module gs2x2_fixed_divider #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [(2*DATA_WIDTH)-1:0] numerator,
    input signed [(2*DATA_WIDTH)-1:0] denominator,
    output reg signed [DATA_WIDTH-1:0] quotient
);

    localparam EXT_WIDTH = (3*DATA_WIDTH);

    reg signed [EXT_WIDTH-1:0] scaled_num;
    reg signed [EXT_WIDTH-1:0] div_result;

    always @* begin
        if (denominator == {2*DATA_WIDTH{1'b0}}) begin
            quotient = {DATA_WIDTH{1'b0}};
        end else begin
            scaled_num = {{DATA_WIDTH{numerator[(2*DATA_WIDTH)-1]}}, numerator} <<< FRAC;
            div_result = scaled_num / denominator;

            if (div_result > $signed({1'b0, {(DATA_WIDTH-1){1'b1}}})) begin
                quotient = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            end else if (div_result < $signed({1'b1, {(DATA_WIDTH-1){1'b0}}})) begin
                quotient = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            end else begin
                quotient = div_result[DATA_WIDTH-1:0];
            end
        end
    end

endmodule