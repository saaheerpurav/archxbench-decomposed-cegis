`timescale 1ns/1ps

module fp_bpf_coeff_rom #(
    parameter TAP_CNT = 63
) (
    output [TAP_CNT*32-1:0] coeffs_fp_flat
);

    genvar i;

    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_COEFFS
            assign coeffs_fp_flat[i*32 +: 32] = coeff_at(i);
        end
    endgenerate

    function [31:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0:  coeff_at = 32'hbb306eeb;
                1:  coeff_at = 32'hbb75b0a5;
                2:  coeff_at = 32'hbbbb295a;
                3:  coeff_at = 32'hbc0bd069;
                4:  coeff_at = 32'hbc3f59f2;
                5:  coeff_at = 32'hbc6787ee;
                6:  coeff_at = 32'hbc6e9b06;
                7:  coeff_at = 32'hbc3ecbfc;
                8:  coeff_at = 32'hbb90d9b1;
                9:  coeff_at = 32'h3bf10411;
                10: coeff_at = 32'h3cbc752e;
                11: coeff_at = 32'h3d27a476;
                12: coeff_at = 32'h3d70effe;
                13: coeff_at = 32'h3d97bf5e;
                14: coeff_at = 32'h3dacccb2;
                15: coeff_at = 32'h3db43958;
                16: coeff_at = 32'h3dacccb2;
                17: coeff_at = 32'h3d97bf5e;
                18: coeff_at = 32'h3d70effe;
                19: coeff_at = 32'h3d27a476;
                20: coeff_at = 32'h3cbc752e;
                21: coeff_at = 32'h3bf10411;
                22: coeff_at = 32'hbb90d9b1;
                23: coeff_at = 32'hbc3ecbfc;
                24: coeff_at = 32'hbc6e9b06;
                25: coeff_at = 32'hbc6787ee;
                26: coeff_at = 32'hbc3f59f2;
                27: coeff_at = 32'hbc0bd069;
                28: coeff_at = 32'hbbbb295a;
                29: coeff_at = 32'hbb75b0a5;
                30: coeff_at = 32'hbb306eeb;
                default: coeff_at = 32'h00000000;
            endcase
        end
    endfunction

endmodule