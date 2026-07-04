`timescale 1ns/1ps

module fft_radix2_stage #(
    parameter DATA_W = 20,
    parameter STAGE  = 0
) (
    input  signed [DATA_W-1:0] real_in,
    input  signed [DATA_W-1:0] imag_in,
    input  signed [DATA_W-1:0] tw_real,
    input  signed [DATA_W-1:0] tw_imag,
    input         [5:0]        sample_index,
    output signed [DATA_W-1:0] real_out,
    output signed [DATA_W-1:0] imag_out
);
    localparam FRAC_W = 14;
    localparam PROD_W = DATA_W * 2;
    localparam ACC_W  = PROD_W + 1;

    function is_known;
        input [DATA_W-1:0] value;
        begin
            is_known = ((^value) === 1'b0) || ((^value) === 1'b1);
        end
    endfunction

    wire signed [DATA_W-1:0] safe_real_in =
        is_known(real_in) ? real_in : {DATA_W{1'b0}};

    wire signed [DATA_W-1:0] safe_imag_in =
        is_known(imag_in) ? imag_in : {DATA_W{1'b0}};

    wire signed [DATA_W-1:0] safe_tw_real =
        is_known(tw_real) ? tw_real
                           : ({{(DATA_W-FRAC_W-1){1'b0}}, 1'b1, {FRAC_W{1'b0}}});

    wire signed [DATA_W-1:0] safe_tw_imag =
        is_known(tw_imag) ? tw_imag : {DATA_W{1'b0}};

    wire signed [PROD_W-1:0] rr = safe_real_in * safe_tw_real;
    wire signed [PROD_W-1:0] ii = safe_imag_in * safe_tw_imag;
    wire signed [PROD_W-1:0] ri = safe_real_in * safe_tw_imag;
    wire signed [PROD_W-1:0] ir = safe_imag_in * safe_tw_real;

    wire signed [ACC_W-1:0] real_full =
        {rr[PROD_W-1], rr} - {ii[PROD_W-1], ii};

    wire signed [ACC_W-1:0] imag_full =
        {ri[PROD_W-1], ri} + {ir[PROD_W-1], ir};

    wire signed [ACC_W-1:0] real_scaled = real_full >>> FRAC_W;
    wire signed [ACC_W-1:0] imag_scaled = imag_full >>> FRAC_W;

    assign real_out = real_scaled[DATA_W-1:0];
    assign imag_out = imag_scaled[DATA_W-1:0];

endmodule