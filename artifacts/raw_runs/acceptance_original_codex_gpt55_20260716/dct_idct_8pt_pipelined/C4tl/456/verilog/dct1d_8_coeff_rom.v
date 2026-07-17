`timescale 1ns/1ps

module dct1d_8_coeff_rom #(
    parameter COEFF_W = 16
) (
    input mode,
    input [2:0] row,
    input [2:0] col,
    output reg signed [COEFF_W-1:0] coeff
);

    always @(*) begin
        coeff = 0;

        if (!mode) begin
            case ({row, col})
                6'o00: coeff = 1024; 6'o01: coeff = 1024; 6'o02: coeff = 1024; 6'o03: coeff = 1024;
                6'o04: coeff = 1024; 6'o05: coeff = 1024; 6'o06: coeff = 1024; 6'o07: coeff = 1024;

                6'o10: coeff = 1004; 6'o11: coeff = 851;  6'o12: coeff = 569;  6'o13: coeff = 200;
                6'o14: coeff = -200; 6'o15: coeff = -569; 6'o16: coeff = -851; 6'o17: coeff = -1004;

                6'o20: coeff = 946;  6'o21: coeff = 392;  6'o22: coeff = -392; 6'o23: coeff = -946;
                6'o24: coeff = -946; 6'o25: coeff = -392; 6'o26: coeff = 392;  6'o27: coeff = 946;

                6'o30: coeff = 851;  6'o31: coeff = -200; 6'o32: coeff = -1004; 6'o33: coeff = -569;
                6'o34: coeff = 569;  6'o35: coeff = 1004; 6'o36: coeff = 200;  6'o37: coeff = -851;

                6'o40: coeff = 724;  6'o41: coeff = -724; 6'o42: coeff = -724; 6'o43: coeff = 724;
                6'o44: coeff = 724;  6'o45: coeff = -724; 6'o46: coeff = -724; 6'o47: coeff = 724;

                6'o50: coeff = 569;  6'o51: coeff = -1004; 6'o52: coeff = 200;  6'o53: coeff = 851;
                6'o54: coeff = -851; 6'o55: coeff = -200;  6'o56: coeff = 1004; 6'o57: coeff = -569;

                6'o60: coeff = 392;  6'o61: coeff = -946; 6'o62: coeff = 946;  6'o63: coeff = -392;
                6'o64: coeff = -392; 6'o65: coeff = 946;  6'o66: coeff = -946; 6'o67: coeff = 392;

                6'o70: coeff = 200;  6'o71: coeff = -569; 6'o72: coeff = 851;  6'o73: coeff = -1004;
                6'o74: coeff = 1004; 6'o75: coeff = -851; 6'o76: coeff = 569;  6'o77: coeff = -200;
            endcase
        end else begin
            case ({row, col})
                6'o00: coeff = 512;  6'o01: coeff = 1004; 6'o02: coeff = 946;  6'o03: coeff = 851;
                6'o04: coeff = 724;  6'o05: coeff = 569;  6'o06: coeff = 392;  6'o07: coeff = 200;

                6'o10: coeff = 512;  6'o11: coeff = 851;  6'o12: coeff = 392;  6'o13: coeff = -200;
                6'o14: coeff = -724; 6'o15: coeff = -1004; 6'o16: coeff = -946; 6'o17: coeff = -569;

                6'o20: coeff = 512;  6'o21: coeff = 569;  6'o22: coeff = -392; 6'o23: coeff = -1004;
                6'o24: coeff = -724; 6'o25: coeff = 200;  6'o26: coeff = 946;  6'o27: coeff = 851;

                6'o30: coeff = 512;  6'o31: coeff = 200;  6'o32: coeff = -946; 6'o33: coeff = -569;
                6'o34: coeff = 724;  6'o35: coeff = 851;  6'o36: coeff = -392; 6'o37: coeff = -1004;

                6'o40: coeff = 512;  6'o41: coeff = -200; 6'o42: coeff = -946; 6'o43: coeff = 569;
                6'o44: coeff = 724;  6'o45: coeff = -851; 6'o46: coeff = -392; 6'o47: coeff = 1004;

                6'o50: coeff = 512;  6'o51: coeff = -569; 6'o52: coeff = -392; 6'o53: coeff = 1004;
                6'o54: coeff = -724; 6'o55: coeff = -200; 6'o56: coeff = 946;  6'o57: coeff = -851;

                6'o60: coeff = 512;  6'o61: coeff = -851; 6'o62: coeff = 392;  6'o63: coeff = 200;
                6'o64: coeff = -724; 6'o65: coeff = 1004; 6'o66: coeff = -946; 6'o67: coeff = 569;

                6'o70: coeff = 512;  6'o71: coeff = -1004; 6'o72: coeff = 946;  6'o73: coeff = -851;
                6'o74: coeff = 724;  6'o75: coeff = -569;  6'o76: coeff = 392;  6'o77: coeff = -200;
            endcase
        end
    end

endmodule