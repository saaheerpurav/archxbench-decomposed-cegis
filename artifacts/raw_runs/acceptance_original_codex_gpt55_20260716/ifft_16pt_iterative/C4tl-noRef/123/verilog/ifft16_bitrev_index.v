module ifft16_bitrev_index #(
    parameter N = 16
) (
    input  wire [3:0] index,
    output reg  [3:0] bitrev_index
);

    always @(*) begin
        case (index)
            4'd0:  bitrev_index = 4'd0;
            4'd1:  bitrev_index = 4'd8;
            4'd2:  bitrev_index = 4'd4;
            4'd3:  bitrev_index = 4'd12;
            4'd4:  bitrev_index = 4'd2;
            4'd5:  bitrev_index = 4'd10;
            4'd6:  bitrev_index = 4'd6;
            4'd7:  bitrev_index = 4'd14;
            4'd8:  bitrev_index = 4'd1;
            4'd9:  bitrev_index = 4'd9;
            4'd10: bitrev_index = 4'd5;
            4'd11: bitrev_index = 4'd13;
            4'd12: bitrev_index = 4'd3;
            4'd13: bitrev_index = 4'd11;
            4'd14: bitrev_index = 4'd7;
            4'd15: bitrev_index = 4'd15;
            default: bitrev_index = 4'd0;
        endcase
    end

endmodule