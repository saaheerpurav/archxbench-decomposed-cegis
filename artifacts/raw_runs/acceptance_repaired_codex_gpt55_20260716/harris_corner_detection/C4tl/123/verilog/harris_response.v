`timescale 1ns/1ps

module harris_response #(
    parameter PROD_W = 32,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input [PROD_W-1:0] ix2,
    input [PROD_W-1:0] iy2,
    input signed [PROD_W-1:0] ixiy,
    input [K_W-1:0] k_param,
    output signed [RESP_W-1:0] response
);

    wire signed [63:0] a = $signed({1'b0, ix2});
    wire signed [63:0] b = $signed({1'b0, iy2});
    wire signed [63:0] c = $signed(ixiy);

    wire signed [63:0] det = (a * b) - (c * c);
    wire signed [63:0] trace = a + b;
    wire signed [63:0] k_term = ($signed({1'b0, k_param}) * trace * trace) >>> 8;
    wire signed [63:0] r_full = det - k_term;

    assign response = r_full[RESP_W-1:0];

endmodule