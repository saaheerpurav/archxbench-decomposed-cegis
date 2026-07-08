`timescale 1ns/1ps

module fp_significand_multiply #(
    parameter MANT_WIDTH = 23
)(
    input  [MANT_WIDTH:0] sig_a,
    input  [MANT_WIDTH:0] sig_b,
    output [((MANT_WIDTH+1)*2)-1:0] sig_product
);

    localparam SIG_WIDTH     = MANT_WIDTH + 1;
    localparam PRODUCT_WIDTH = SIG_WIDTH * 2;

    wire [SIG_WIDTH-1:0] a_ext;
    wire [SIG_WIDTH-1:0] b_ext;

    assign a_ext = sig_a;
    assign b_ext = sig_b;

    assign sig_product = a_ext * b_ext;

endmodule