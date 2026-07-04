`timescale 1ns/1ps

module fft_stage_unit #(
    parameter W = 20,
    parameter STAGE_ID = 0
) (
    input  signed [W-1:0] real_in,
    input  signed [W-1:0] imag_in,
    input  signed [W-1:0] tw_real,
    input  signed [W-1:0] tw_imag,
    output signed [W-1:0] real_out,
    output signed [W-1:0] imag_out
);
    localparam SHIFT = (W > 2) ? (W - 2) : 0;

    wire signed [(2*W)-1:0] mult_rr;
    wire signed [(2*W)-1:0] mult_ii;
    wire signed [(2*W)-1:0] mult_ri;
    wire signed [(2*W)-1:0] mult_ir;

    wire signed [2*W:0] prod_real;
    wire signed [2*W:0] prod_imag;

    assign mult_rr = real_in * tw_real;
    assign mult_ii = imag_in * tw_imag;
    assign mult_ri = real_in * tw_imag;
    assign mult_ir = imag_in * tw_real;

    assign prod_real = $signed({mult_rr[(2*W)-1], mult_rr}) -
                       $signed({mult_ii[(2*W)-1], mult_ii});

    assign prod_imag = $signed({mult_ri[(2*W)-1], mult_ri}) +
                       $signed({mult_ir[(2*W)-1], mult_ir});

    assign real_out = round_shift_saturate(prod_real);
    assign imag_out = round_shift_saturate(prod_imag);

    function signed [W-1:0] round_shift_saturate;
        input signed [2*W:0] value;

        reg signed [2*W:0] rounded;
        reg signed [2*W:0] shifted;
        reg signed [2*W:0] max_w;
        reg signed [2*W:0] min_w;
        reg signed [2*W:0] round_const;
        begin
            max_w = {1'b0, {W-1{1'b1}}};
            min_w = {1'b1, {W-1{1'b0}}};

            if (SHIFT == 0) begin
                shifted = value;
            end else begin
                round_const = {{(2*W){1'b0}}, 1'b1} <<< (SHIFT - 1);

                if (value[2*W])
                    rounded = value - round_const;
                else
                    rounded = value + round_const;

                shifted = rounded >>> SHIFT;
            end

            if (shifted > max_w)
                round_shift_saturate = {1'b0, {W-1{1'b1}}};
            else if (shifted < min_w)
                round_shift_saturate = {1'b1, {W-1{1'b0}}};
            else
                round_shift_saturate = shifted[W-1:0];
        end
    endfunction
endmodule