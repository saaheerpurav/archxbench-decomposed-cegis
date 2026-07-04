`timescale 1ns/1ps

module nr_fixed_div #(
    parameter FRAC = 8,
    parameter EXT  = 64
)(
    input  signed [EXT-1:0] numerator,
    input  signed [EXT-1:0] denominator,
    output reg signed [EXT-1:0] quotient,
    output divide_by_zero
);

    localparam signed [EXT-1:0] Q_MAX = {1'b0, {EXT-1{1'b1}}};
    localparam signed [EXT-1:0] Q_MIN = {1'b1, {EXT-1{1'b0}}};

    reg signed [(2*EXT)-1:0] scaled_num;
    reg signed [(2*EXT)-1:0] div_result;

    assign divide_by_zero = (denominator == {EXT{1'b0}});

    always @* begin
        scaled_num = {{EXT{numerator[EXT-1]}}, numerator} << FRAC;
        div_result = {2*EXT{1'b0}};

        if (divide_by_zero) begin
            quotient = {EXT{1'b0}};
        end else begin
            div_result = scaled_num / denominator;

            if (div_result > {{EXT{Q_MAX[EXT-1]}}, Q_MAX}) begin
                quotient = Q_MAX;
            end else if (div_result < {{EXT{Q_MIN[EXT-1]}}, Q_MIN}) begin
                quotient = Q_MIN;
            end else begin
                quotient = div_result[EXT-1:0];
            end
        end
    end

endmodule