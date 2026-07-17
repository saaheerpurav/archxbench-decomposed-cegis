`timescale 1ns/1ps

module highpass_fir_coeff_rom #(
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16
) (
    output signed [TAP_CNT*COEFF_W-1:0] coeff_vector
);
    assign coeff_vector = {
        16'sd0, 16'sd10, 16'sd17, 16'sd19, 16'sd13, 16'sd0, -16'sd16, -16'sd29, -16'sd32, -16'sd23,
        16'sd0, 16'sd29, 16'sd53, 16'sd60, 16'sd42, 16'sd0, -16'sd53, -16'sd96, -16'sd107, -16'sd73,
        16'sd0, 16'sd90, 16'sd161, 16'sd177, 16'sd121, 16'sd0, -16'sd145, -16'sd258, -16'sd282, -16'sd191,
        16'sd0, 16'sd229, 16'sd406, 16'sd444, 16'sd301, 16'sd0, -16'sd365, -16'sd652, -16'sd724, -16'sd499,
        16'sd0, 16'sd633, 16'sd1170, 16'sd1355, 16'sd989, 16'sd0, -16'sd1511, -16'sd3280, -16'sd4943, -16'sd6126,
        16'sd26219, -16'sd6126, -16'sd4943, -16'sd3280, -16'sd1511, 16'sd0, 16'sd989, 16'sd1355, 16'sd1170, 16'sd633,
        16'sd0, -16'sd499, -16'sd724, -16'sd652, -16'sd365, 16'sd0, 16'sd301, 16'sd444, 16'sd406, 16'sd229,
        16'sd0, -16'sd191, -16'sd282, -16'sd258, -16'sd145, 16'sd0, 16'sd121, 16'sd177, 16'sd161, 16'sd90,
        16'sd0, -16'sd73, -16'sd107, -16'sd96, -16'sd53, 16'sd0, 16'sd42, 16'sd60, 16'sd53, 16'sd29,
        16'sd0, -16'sd23, -16'sd32, -16'sd29, -16'sd16, 16'sd0, 16'sd13, 16'sd19, 16'sd17, 16'sd10,
        16'sd0
    };
endmodule