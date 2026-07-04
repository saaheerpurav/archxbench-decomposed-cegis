`timescale 1ns/1ps

module fp_add_execute (
    input large_sign,
    input small_sign,
    input [7:0] common_exp,
    input [26:0] large_sig,
    input [26:0] small_sig,
    output reg result_sign,
    output [7:0] result_exp,
    output reg [27:0] sum,
    output sum_zero
);

assign result_exp = common_exp;
assign sum_zero = (sum == 28'b0);

always @* begin
    sum = 28'b0;
    result_sign = 1'b0;

    if (large_sign == small_sign) begin
        sum = {1'b0, large_sig} + {1'b0, small_sig};
        result_sign = large_sign;
    end else begin
        if (large_sig > small_sig) begin
            sum = {1'b0, large_sig} - {1'b0, small_sig};
            result_sign = large_sign;
        end else if (small_sig > large_sig) begin
            sum = {1'b0, small_sig} - {1'b0, large_sig};
            result_sign = small_sign;
        end else begin
            sum = 28'b0;
            result_sign = 1'b0;
        end
    end
end

endmodule