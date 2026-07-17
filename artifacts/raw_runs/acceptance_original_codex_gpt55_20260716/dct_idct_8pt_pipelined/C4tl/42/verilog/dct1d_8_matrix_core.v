`timescale 1ns/1ps

module dct1d_8_matrix_core #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input mode,
    input [2:0] out_index,
    input signed [DATA_W-1:0] x0,
    input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,
    input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,
    input signed [DATA_W-1:0] x7,
    output signed [OUT_W-1:0] y
);

    localparam ACC_W = DATA_W + COEFF_W + 4;

    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
    wire signed [ACC_W-1:0] acc;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c0 (.mode(mode), .row(out_index), .col(3'd0), .coeff(c0));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c1 (.mode(mode), .row(out_index), .col(3'd1), .coeff(c1));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c2 (.mode(mode), .row(out_index), .col(3'd2), .coeff(c2));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c3 (.mode(mode), .row(out_index), .col(3'd3), .coeff(c3));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c4 (.mode(mode), .row(out_index), .col(3'd4), .coeff(c4));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c5 (.mode(mode), .row(out_index), .col(3'd5), .coeff(c5));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c6 (.mode(mode), .row(out_index), .col(3'd6), .coeff(c6));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c7 (.mode(mode), .row(out_index), .col(3'd7), .coeff(c7));

    dct1d_8_mac8 #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .x0(x0), .x1(x1), .x2(x2), .x3(x3),
        .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3),
        .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .acc(acc)
    );

    dct1d_8_round_clip #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .FRAC_W(14)
    ) u_round_clip (
        .acc(acc),
        .y(y)
    );

endmodule