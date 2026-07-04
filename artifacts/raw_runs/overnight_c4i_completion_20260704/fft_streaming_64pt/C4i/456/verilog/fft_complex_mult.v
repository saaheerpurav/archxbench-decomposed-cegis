`timescale 1ns/1ps

module fft_complex_mult #(
    parameter DATA_W = 20,
    parameter FRAC_W = 14
) (
    input  signed [DATA_W-1:0] a_real,
    input  signed [DATA_W-1:0] a_imag,
    input  signed [DATA_W-1:0] b_real,
    input  signed [DATA_W-1:0] b_imag,
    output signed [DATA_W-1:0] p_real,
    output signed [DATA_W-1:0] p_imag
);

    function signed [DATA_W-1:0] known_or_zero;
        input signed [DATA_W-1:0] value;
        begin
            if (^value === 1'bx)
                known_or_zero = {DATA_W{1'b0}};
            else
                known_or_zero = value;
        end
    endfunction

    wire signed [DATA_W-1:0] ar = known_or_zero(a_real);
    wire signed [DATA_W-1:0] ai = known_or_zero(a_imag);
    wire signed [DATA_W-1:0] br = known_or_zero(b_real);
    wire signed [DATA_W-1:0] bi = known_or_zero(b_imag);

    wire signed [(2*DATA_W)-1:0] rr = ar * br;
    wire signed [(2*DATA_W)-1:0] ii = ai * bi;
    wire signed [(2*DATA_W)-1:0] ri = ar * bi;
    wire signed [(2*DATA_W)-1:0] ir = ai * br;

    wire signed [(2*DATA_W):0] real_full =
        {rr[(2*DATA_W)-1], rr} - {ii[(2*DATA_W)-1], ii};

    wire signed [(2*DATA_W):0] imag_full =
        {ri[(2*DATA_W)-1], ri} + {ir[(2*DATA_W)-1], ir};

    assign p_real = (real_full >>> FRAC_W);
    assign p_imag = (imag_full >>> FRAC_W);

endmodule