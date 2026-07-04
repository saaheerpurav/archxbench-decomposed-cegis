`timescale 1ns/1ps

module fp_mult_pack (
    input sign,
    input signed [10:0] exp_in,
    input [22:0] frac_in,
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output [31:0] result
);

localparam [31:0] CANONICAL_NAN = 32'h7FC00000;

wire invalid_inf_zero;
wire any_nan;
wire any_inf;
wire any_zero;
wire overflow;
wire normal;

assign invalid_inf_zero = (zero_a && inf_b) || (zero_b && inf_a);
assign any_nan = nan_a || nan_b || invalid_inf_zero;
assign any_inf = inf_a || inf_b;
assign any_zero = zero_a || zero_b;

assign overflow = (exp_in >= 11'sd255);
assign normal = (exp_in >= 11'sd1);

assign result =
    any_nan  ? CANONICAL_NAN :
    any_inf  ? {sign, 8'hFF, 23'b0} :
    any_zero ? {sign, 31'b0} :
    overflow ? {sign, 8'hFF, 23'b0} :
    normal   ? {sign, exp_in[7:0], frac_in} :
               {sign, 31'b0};

endmodule