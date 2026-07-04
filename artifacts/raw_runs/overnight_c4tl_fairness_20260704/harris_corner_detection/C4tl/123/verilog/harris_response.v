`timescale 1ns/1ps

module harris_response #(
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

    wire signed [2*IN_W-1:0] det_full;
    wire signed [2*IN_W-1:0] cross_full;
    wire [IN_W:0] trace_full;
    wire [2*IN_W+1:0] trace_sq_full;
    wire signed [2*IN_W+K_W+1:0] k_term_full;
    wire signed [2*IN_W+K_W+2:0] resp_full;

    assign cross_full = ixy * ixy;
    assign det_full = ix2 * iy2 - cross_full;
    assign trace_full = ix2 + iy2;
    assign trace_sq_full = trace_full * trace_full;
    assign k_term_full = (trace_sq_full * k_param) >>> 8;
    assign resp_full = det_full - k_term_full;

    assign response = resp_full[RESP_W-1:0];

endmodule