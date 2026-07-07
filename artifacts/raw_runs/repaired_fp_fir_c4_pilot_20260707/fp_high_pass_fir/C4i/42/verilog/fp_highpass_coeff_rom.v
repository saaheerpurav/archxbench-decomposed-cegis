`timescale 1ns/1ps

module fp_highpass_coeff_rom #(
    parameter TAP_CNT = 31
) (
    output [TAP_CNT*32-1:0] coeffs_flat
);

    genvar i;

    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_COEFF
            if (i == 0)       assign coeffs_flat[i*32 +: 32] = 32'ha1381601;
            else if (i == 1)  assign coeffs_flat[i*32 +: 32] = 32'hba9dbdb2;
            else if (i == 2)  assign coeffs_flat[i*32 +: 32] = 32'hbb36c8a9;
            else if (i == 3)  assign coeffs_flat[i*32 +: 32] = 32'hbb8ac191;
            else if (i == 4)  assign coeffs_flat[i*32 +: 32] = 32'hbb816a82;
            else if (i == 5)  assign coeffs_flat[i*32 +: 32] = 32'h22325551;
            else if (i == 6)  assign coeffs_flat[i*32 +: 32] = 32'h3c07824b;
            else if (i == 7)  assign coeffs_flat[i*32 +: 32] = 32'h3c987e0d;
            else if (i == 8)  assign coeffs_flat[i*32 +: 32] = 32'h3cd058cf;
            else if (i == 9)  assign coeffs_flat[i*32 +: 32] = 32'h3cae415b;
            else if (i == 10) assign coeffs_flat[i*32 +: 32] = 32'ha2dd7a7a;
            else if (i == 11) assign coeffs_flat[i*32 +: 32] = 32'hbd226db2;
            else if (i == 12) assign coeffs_flat[i*32 +: 32] = 32'hbdbc821d;
            else if (i == 13) assign coeffs_flat[i*32 +: 32] = 32'hbe14d580;
            else if (i == 14) assign coeffs_flat[i*32 +: 32] = 32'hbe3da98f;
            else if (i == 15) assign coeffs_flat[i*32 +: 32] = 32'h3f4ccccd;
            else if (i == 16) assign coeffs_flat[i*32 +: 32] = 32'hbe3da98f;
            else if (i == 17) assign coeffs_flat[i*32 +: 32] = 32'hbe14d580;
            else if (i == 18) assign coeffs_flat[i*32 +: 32] = 32'hbdbc821d;
            else if (i == 19) assign coeffs_flat[i*32 +: 32] = 32'hbd226db2;
            else if (i == 20) assign coeffs_flat[i*32 +: 32] = 32'ha2dd7a7a;
            else if (i == 21) assign coeffs_flat[i*32 +: 32] = 32'h3cae415b;
            else if (i == 22) assign coeffs_flat[i*32 +: 32] = 32'h3cd058cf;
            else if (i == 23) assign coeffs_flat[i*32 +: 32] = 32'h3c987e0d;
            else if (i == 24) assign coeffs_flat[i*32 +: 32] = 32'h3c07824b;
            else if (i == 25) assign coeffs_flat[i*32 +: 32] = 32'h22325551;
            else if (i == 26) assign coeffs_flat[i*32 +: 32] = 32'hbb816a82;
            else if (i == 27) assign coeffs_flat[i*32 +: 32] = 32'hbb8ac191;
            else if (i == 28) assign coeffs_flat[i*32 +: 32] = 32'hbb36c8a9;
            else if (i == 29) assign coeffs_flat[i*32 +: 32] = 32'hba9dbdb2;
            else if (i == 30) assign coeffs_flat[i*32 +: 32] = 32'ha1381601;
            else              assign coeffs_flat[i*32 +: 32] = 32'h00000000;
        end
    endgenerate

endmodule