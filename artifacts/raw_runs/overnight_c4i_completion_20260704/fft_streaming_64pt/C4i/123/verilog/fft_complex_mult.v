`timescale 1ns/1ps

module fft_complex_mult #(
    parameter DATA_W = 20,
    parameter TW_W = 16,
    parameter TW_FRAC = 14
) (
    input  signed [DATA_W-1:0] a_re,
    input  signed [DATA_W-1:0] a_im,
    input  signed [TW_W-1:0]   b_re,
    input  signed [TW_W-1:0]   b_im,
    output signed [DATA_W-1:0] p_re,
    output signed [DATA_W-1:0] p_im
);

    localparam PROD_W = DATA_W + TW_W;
    localparam ACC_W  = PROD_W + 1;

    wire signed [PROD_W-1:0] ar_br;
    wire signed [PROD_W-1:0] ai_bi;
    wire signed [PROD_W-1:0] ar_bi;
    wire signed [PROD_W-1:0] ai_br;

    wire signed [ACC_W-1:0] re_full;
    wire signed [ACC_W-1:0] im_full;

    assign ar_br = a_re * b_re;
    assign ai_bi = a_im * b_im;
    assign ar_bi = a_re * b_im;
    assign ai_br = a_im * b_re;

    assign re_full = $signed({ar_br[PROD_W-1], ar_br})
                   - $signed({ai_bi[PROD_W-1], ai_bi});

    assign im_full = $signed({ar_bi[PROD_W-1], ar_bi})
                   + $signed({ai_br[PROD_W-1], ai_br});

    assign p_re = re_full >>> TW_FRAC;
    assign p_im = im_full >>> TW_FRAC;

endmodule