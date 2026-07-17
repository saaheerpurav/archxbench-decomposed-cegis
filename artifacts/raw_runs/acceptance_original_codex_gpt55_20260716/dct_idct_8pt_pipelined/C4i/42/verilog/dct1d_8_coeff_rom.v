`timescale 1ns/1ps

module dct1d_8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input mode,
    input [2:0] row,
    input [2:0] col,
    output reg signed [COEFF_W-1:0] coeff
);

    function signed [15:0] dct_c;
        input [2:0] r;
        input [2:0] n;
        begin
            case ({r, n})
                6'o00, 6'o01, 6'o02, 6'o03,
                6'o04, 6'o05, 6'o06, 6'o07: dct_c = 16'sd5793;

                6'o10: dct_c =  16'sd8035; 6'o11: dct_c =  16'sd6811;
                6'o12: dct_c =  16'sd4551; 6'o13: dct_c =  16'sd1598;
                6'o14: dct_c = -16'sd1598; 6'o15: dct_c = -16'sd4551;
                6'o16: dct_c = -16'sd6811; 6'o17: dct_c = -16'sd8035;

                6'o20: dct_c =  16'sd7568; 6'o21: dct_c =  16'sd3135;
                6'o22: dct_c = -16'sd3135; 6'o23: dct_c = -16'sd7568;
                6'o24: dct_c = -16'sd7568; 6'o25: dct_c = -16'sd3135;
                6'o26: dct_c =  16'sd3135; 6'o27: dct_c =  16'sd7568;

                6'o30: dct_c =  16'sd6811; 6'o31: dct_c = -16'sd1598;
                6'o32: dct_c = -16'sd8035; 6'o33: dct_c = -16'sd4551;
                6'o34: dct_c =  16'sd4551; 6'o35: dct_c =  16'sd8035;
                6'o36: dct_c =  16'sd1598; 6'o37: dct_c = -16'sd6811;

                6'o40: dct_c =  16'sd5793; 6'o41: dct_c = -16'sd5793;
                6'o42: dct_c = -16'sd5793; 6'o43: dct_c =  16'sd5793;
                6'o44: dct_c =  16'sd5793; 6'o45: dct_c = -16'sd5793;
                6'o46: dct_c = -16'sd5793; 6'o47: dct_c =  16'sd5793;

                6'o50: dct_c =  16'sd4551; 6'o51: dct_c = -16'sd8035;
                6'o52: dct_c =  16'sd1598; 6'o53: dct_c =  16'sd6811;
                6'o54: dct_c = -16'sd6811; 6'o55: dct_c = -16'sd1598;
                6'o56: dct_c =  16'sd8035; 6'o57: dct_c = -16'sd4551;

                6'o60: dct_c =  16'sd3135; 6'o61: dct_c = -16'sd7568;
                6'o62: dct_c =  16'sd7568; 6'o63: dct_c = -16'sd3135;
                6'o64: dct_c = -16'sd3135; 6'o65: dct_c =  16'sd7568;
                6'o66: dct_c = -16'sd7568; 6'o67: dct_c =  16'sd3135;

                6'o70: dct_c =  16'sd1598; 6'o71: dct_c = -16'sd4551;
                6'o72: dct_c =  16'sd6811; 6'o73: dct_c = -16'sd8035;
                6'o74: dct_c =  16'sd8035; 6'o75: dct_c = -16'sd6811;
                6'o76: dct_c =  16'sd4551; 6'o77: dct_c = -16'sd1598;

                default: dct_c = 16'sd0;
            endcase
        end
    endfunction

    always @(*) begin
        if (mode)
            coeff = dct_c(col, row);
        else
            coeff = dct_c(row, col);
    end

endmodule