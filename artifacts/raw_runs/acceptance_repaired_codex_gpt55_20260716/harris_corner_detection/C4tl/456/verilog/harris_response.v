`timescale 1ns/1ps

module harris_response #(
    parameter IN_W = 38,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input [IN_W-1:0] ix2,
    input [IN_W-1:0] iy2,
    input signed [IN_W-1:0] ixy,
    input [K_W-1:0] k_param,
    output signed [RESP_W-1:0] response
);
    wire signed [95:0] det;
    wire signed [95:0] trace;
    wire signed [95:0] trace_sq;
    wire signed [95:0] k_term;
    wire signed [95:0] r_full;

    assign det = ($signed({1'b0,ix2}) * $signed({1'b0,iy2})) - ($signed(ixy) * $signed(ixy));
    assign trace = $signed({1'b0,ix2}) + $signed({1'b0,iy2});
    assign trace_sq = trace * trace;
    assign k_term = ($signed({1'b0,k_param}) * trace_sq) / 100;
    assign r_full = det - k_term;

    assign response =
        (r_full > $signed({1'b0,{(RESP_W-1){1'b1}}})) ? {1'b0,{(RESP_W-1){1'b1}}} :
        (r_full < $signed({1'b1,{(RESP_W-1){1'b0}}})) ? {1'b1,{(RESP_W-1){1'b0}}} :
        r_full[RESP_W-1:0];
endmodule