`timescale 1ns/1ps

module dct1d_8_matrix_mac #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter ACC_W = 36
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
    output signed [ACC_W-1:0] acc_out
);

    wire signed [COEFF_W-1:0] c0;
    wire signed [COEFF_W-1:0] c1;
    wire signed [COEFF_W-1:0] c2;
    wire signed [COEFF_W-1:0] c3;
    wire signed [COEFF_W-1:0] c4;
    wire signed [COEFF_W-1:0] c5;
    wire signed [COEFF_W-1:0] c6;
    wire signed [COEFF_W-1:0] c7;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c0 (.mode(mode), .row(out_index), .col(3'd0), .coeff(c0));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c1 (.mode(mode), .row(out_index), .col(3'd1), .coeff(c1));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c2 (.mode(mode), .row(out_index), .col(3'd2), .coeff(c2));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c3 (.mode(mode), .row(out_index), .col(3'd3), .coeff(c3));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c4 (.mode(mode), .row(out_index), .col(3'd4), .coeff(c4));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c5 (.mode(mode), .row(out_index), .col(3'd5), .coeff(c5));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c6 (.mode(mode), .row(out_index), .col(3'd6), .coeff(c6));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) u_c7 (.mode(mode), .row(out_index), .col(3'd7), .coeff(c7));

    assign acc_out =
        $signed(x0) * $signed(c0) +
        $signed(x1) * $signed(c1) +
        $signed(x2) * $signed(c2) +
        $signed(x3) * $signed(c3) +
        $signed(x4) * $signed(c4) +
        $signed(x5) * $signed(c5) +
        $signed(x6) * $signed(c6) +
        $signed(x7) * $signed(c7);

endmodule