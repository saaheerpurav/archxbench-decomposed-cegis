`timescale 1ns/1ps

module fft_complex_mult #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] a_real,
    input  signed [DATA_W-1:0] a_imag,
    input  signed [DATA_W-1:0] b_real,
    input  signed [DATA_W-1:0] b_imag,
    output signed [DATA_W-1:0] p_real,
    output signed [DATA_W-1:0] p_imag
);
    localparam SHIFT = DATA_W - 1;

    wire signed [(2*DATA_W)-1:0] rr = a_real * b_real;
    wire signed [(2*DATA_W)-1:0] ii = a_imag * b_imag;
    wire signed [(2*DATA_W)-1:0] ri = a_real * b_imag;
    wire signed [(2*DATA_W)-1:0] ir = a_imag * b_real;

    wire signed [(2*DATA_W):0] real_full =
        {rr[(2*DATA_W)-1], rr} - {ii[(2*DATA_W)-1], ii};

    wire signed [(2*DATA_W):0] imag_full =
        {ri[(2*DATA_W)-1], ri} + {ir[(2*DATA_W)-1], ir};

    function signed [DATA_W-1:0] round_shift_saturate;
        input signed [(2*DATA_W):0] value;
        reg   signed [(2*DATA_W):0] rounded;
        reg   signed [(2*DATA_W):0] shifted;
        reg   signed [(2*DATA_W):0] max_val;
        reg   signed [(2*DATA_W):0] min_val;
        begin
            max_val = {{(DATA_W+1){1'b0}}, 1'b0, {(DATA_W-1){1'b1}}};
            min_val = {{(DATA_W+1){1'b1}}, 1'b1, {(DATA_W-1){1'b0}}};

            if (SHIFT > 0)
                rounded = value + {{(2*DATA_W-SHIFT+1){1'b0}}, 1'b1, {(SHIFT-1){1'b0}}};
            else
                rounded = value;

            shifted = rounded >>> SHIFT;

            if (shifted > max_val)
                round_shift_saturate = {1'b0, {(DATA_W-1){1'b1}}};
            else if (shifted < min_val)
                round_shift_saturate = {1'b1, {(DATA_W-1){1'b0}}};
            else
                round_shift_saturate = shifted[DATA_W-1:0];
        end
    endfunction

    assign p_real = round_shift_saturate(real_full);
    assign p_imag = round_shift_saturate(imag_full);

endmodule