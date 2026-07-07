`timescale 1ns/1ps

module fp32_to_q #(
    parameter Q = 20
) (
    input      [31:0] fp_in,
    output reg signed [31:0] q_out
);
    reg sign;
    reg [7:0] exp;
    reg [23:0] mant;
    reg [63:0] mag;
    integer sh;

    always @* begin
        sign = fp_in[31];
        exp  = fp_in[30:23];

        if (exp == 8'd0) begin
            q_out = 32'sd0;
        end else if (exp == 8'hff) begin
            q_out = sign ? -32'sh7fffffff : 32'sh7fffffff;
        end else begin
            mant = {1'b1, fp_in[22:0]};
            sh = exp - 127 - 23 + Q;

            if (sh >= 0)
                mag = {40'd0, mant} << sh;
            else if (sh <= -63)
                mag = 64'd0;
            else
                mag = ({40'd0, mant} + (64'd1 << ((-sh)-1))) >> (-sh);

            if (mag[63:31] != 33'd0)
                q_out = sign ? -32'sh7fffffff : 32'sh7fffffff;
            else
                q_out = sign ? -$signed(mag[31:0]) : $signed(mag[31:0]);
        end
    end
endmodule