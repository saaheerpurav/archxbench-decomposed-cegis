`timescale 1ns/1ps

module q_to_fp32 #(
    parameter IN_Q = 44,
    parameter IN_W = 64
) (
    input signed [IN_W-1:0] q_in,
    output reg [31:0] fp_out
);
    reg sign;
    reg [IN_W-1:0] mag;
    reg [IN_W-1:0] norm;
    reg [7:0] exp;
    reg [22:0] frac;
    integer msb;
    integer i;
    integer sh;
    reg [63:0] rounded;

    always @* begin
        if (q_in == 0) begin
            fp_out = 32'h00000000;
        end else begin
            sign = q_in[IN_W-1];
            mag = sign ? -q_in : q_in;

            msb = 0;
            for (i = 0; i < IN_W; i = i + 1) begin
                if (mag[i])
                    msb = i;
            end

            exp = 127 + msb - IN_Q;

            if ((127 + msb - IN_Q) <= 0) begin
                fp_out = 32'h00000000;
            end else if ((127 + msb - IN_Q) >= 255) begin
                fp_out = {sign, 8'hff, 23'd0};
            end else begin
                if (msb > 23) begin
                    sh = msb - 23;
                    rounded = (mag + ({{63{1'b0}},1'b1} << (sh-1))) >> sh;
                    frac = rounded[22:0];
                    if (rounded[24]) begin
                        exp = exp + 1'b1;
                        frac = rounded[23:1];
                    end
                end else begin
                    norm = mag << (23 - msb);
                    frac = norm[22:0];
                end

                fp_out = {sign, exp, frac};
            end
        end
    end
endmodule