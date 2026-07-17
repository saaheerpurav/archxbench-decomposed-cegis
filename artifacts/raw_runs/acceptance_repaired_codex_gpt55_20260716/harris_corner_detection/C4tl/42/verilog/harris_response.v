`timescale 1ns/1ps

module harris_response #(
    parameter IN_W = 40,
    parameter RESP_W = 32,
    parameter K_W = 8,
    parameter CALC_W = 64
) (
    input [IN_W-1:0] ix2,
    input [IN_W-1:0] iy2,
    input signed [IN_W-1:0] ixy,
    input [K_W-1:0] k_param,
    output signed [RESP_W-1:0] response
);
    wire signed [CALC_W-1:0] ix2_s = ix2;
    wire signed [CALC_W-1:0] iy2_s = iy2;
    wire signed [CALC_W-1:0] ixy_s = ixy;

    wire signed [CALC_W-1:0] det = (ix2_s * iy2_s) - (ixy_s * ixy_s);
    wire signed [CALC_W-1:0] trace = ix2_s + iy2_s;
    wire signed [CALC_W-1:0] trace_sq = trace * trace;
    wire signed [CALC_W-1:0] k_term = (trace_sq * k_param) >>> K_W;
    wire signed [CALC_W-1:0] resp_full = det - k_term;

    assign response = resp_full[RESP_W-1:0];
endmodule