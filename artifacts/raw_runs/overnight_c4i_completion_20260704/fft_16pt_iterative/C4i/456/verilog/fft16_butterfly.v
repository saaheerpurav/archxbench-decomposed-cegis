`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  mode,
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y_a_real,
    output signed [DATA_W-1:0]  y_a_imag,
    output signed [DATA_W-1:0]  y_b_real,
    output signed [DATA_W-1:0]  y_b_imag
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    localparam signed [ACC_W-1:0] ROUND_CONST = 16384;

    wire signed [COEFF_W-1:0] eff_sin;
    assign eff_sin = mode ? -tw_sin : tw_sin;

    wire signed [PROD_W-1:0] prod_real_cos;
    wire signed [PROD_W-1:0] prod_imag_sin;
    wire signed [PROD_W-1:0] prod_imag_cos;
    wire signed [PROD_W-1:0] prod_real_sin;

    assign prod_real_cos = $signed(b_real) * $signed(tw_cos);
    assign prod_imag_sin = $signed(b_imag) * $signed(eff_sin);
    assign prod_imag_cos = $signed(b_imag) * $signed(tw_cos);
    assign prod_real_sin = $signed(b_real) * $signed(eff_sin);

    wire signed [ACC_W-1:0] real_prod;
    wire signed [ACC_W-1:0] imag_prod;

    assign real_prod = $signed({{2{prod_real_cos[PROD_W-1]}}, prod_real_cos})
                     + $signed({{2{prod_imag_sin[PROD_W-1]}}, prod_imag_sin});

    assign imag_prod = $signed({{2{prod_imag_cos[PROD_W-1]}}, prod_imag_cos})
                     - $signed({{2{prod_real_sin[PROD_W-1]}}, prod_real_sin});

    wire signed [ACC_W-1:0] real_round;
    wire signed [ACC_W-1:0] imag_round;

    assign real_round = real_prod + ROUND_CONST;
    assign imag_round = imag_prod + ROUND_CONST;

    wire signed [DATA_W-1:0] t_real;
    wire signed [DATA_W-1:0] t_imag;

    assign t_real = real_round >>> 15;
    assign t_imag = imag_round >>> 15;

    assign y_a_real = a_real + t_real;
    assign y_a_imag = a_imag + t_imag;
    assign y_b_real = a_real - t_real;
    assign y_b_imag = a_imag - t_imag;

endmodule