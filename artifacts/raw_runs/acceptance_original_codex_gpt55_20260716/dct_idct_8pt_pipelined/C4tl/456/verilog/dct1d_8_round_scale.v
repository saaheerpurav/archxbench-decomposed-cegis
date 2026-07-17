`timescale 1ns/1ps

module dct1d_8_round_scale #(
    parameter ACC_W = 36,
    parameter OUT_W = 18,
    parameter FRAC_W = 10
) (
    input mode,
    input signed [ACC_W-1:0] acc_in,
    output signed [OUT_W-1:0] scaled_out
);

    wire signed [ACC_W-1:0] dct_round;
    wire signed [ACC_W-1:0] idct_round;
    wire signed [ACC_W-1:0] rounded;
    wire signed [ACC_W-1:0] shifted;

    assign dct_round  = acc_in + (acc_in >= 0 ? ({{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}}) :
                                              -({{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}}));
    assign idct_round = acc_in + (acc_in >= 0 ? ({{(ACC_W-(FRAC_W+2)){1'b0}}, 1'b1, {(FRAC_W+1){1'b0}}}) :
                                              -({{(ACC_W-(FRAC_W+2)){1'b0}}, 1'b1, {(FRAC_W+1){1'b0}}}));

    assign rounded = mode ? idct_round : dct_round;
    assign shifted = mode ? (rounded >>> (FRAC_W + 2)) : (rounded >>> FRAC_W);

    dct1d_8_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .in_val(shifted),
        .out_val(scaled_out)
    );

endmodule