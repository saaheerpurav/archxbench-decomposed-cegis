`timescale 1ns/1ps

module harris_response_calc #(
    parameter IN_W = 36,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input [IN_W-1:0] ix2,
    input [IN_W-1:0] iy2,
    input signed [IN_W-1:0] ixy,
    input [K_W-1:0] k_param,
    output signed [RESP_W-1:0] response
);

    wire [2*IN_W-1:0] det_a;
    wire [2*IN_W-1:0] det_b;
    wire signed [2*IN_W:0] det_full;
    wire [IN_W:0] trace;
    wire [2*IN_W+1:0] trace_sq;
    wire [2*IN_W+K_W+1:0] k_term;
    wire signed [2*IN_W+K_W+2:0] resp_full;

    assign det_a = ix2 * iy2;
    assign det_b = ixy * ixy;
    assign det_full = $signed({1'b0, det_a}) - $signed({1'b0, det_b});

    assign trace = {1'b0, ix2} + {1'b0, iy2};
    assign trace_sq = trace * trace;
    assign k_term = trace_sq * k_param;

    assign resp_full = {{(K_W+2){det_full[2*IN_W]}}, det_full} -
                       $signed({1'b0, k_term});

    assign response = (resp_full < 0) ? {RESP_W{1'b0}} :
                      (|resp_full[2*IN_W+K_W+2:RESP_W]) ? {1'b0, {(RESP_W-1){1'b1}}} :
                      resp_full[RESP_W-1:0];

endmodule