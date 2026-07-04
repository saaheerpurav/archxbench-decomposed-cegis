`timescale 1ns/1ps

module ifft16_bit_reverse_index #(
    parameter INDEX = 0
) (
    output [3:0] reversed
);
    assign reversed =
        (INDEX == 0)  ? 4'd0  :
        (INDEX == 1)  ? 4'd8  :
        (INDEX == 2)  ? 4'd4  :
        (INDEX == 3)  ? 4'd12 :
        (INDEX == 4)  ? 4'd2  :
        (INDEX == 5)  ? 4'd10 :
        (INDEX == 6)  ? 4'd6  :
        (INDEX == 7)  ? 4'd14 :
        (INDEX == 8)  ? 4'd1  :
        (INDEX == 9)  ? 4'd9  :
        (INDEX == 10) ? 4'd5  :
        (INDEX == 11) ? 4'd13 :
        (INDEX == 12) ? 4'd3  :
        (INDEX == 13) ? 4'd11 :
        (INDEX == 14) ? 4'd7  :
                        4'd15;
endmodule