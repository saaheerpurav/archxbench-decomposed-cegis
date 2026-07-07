`timescale 1ns/1ps

module fp_bpf_q16_to_fp32 (
    input  signed [47:0] q_in,
    output [31:0]        fp_out
);
    reg [31:0] fp_r;
    reg        sign;
    reg [47:0] mag;
    reg [47:0] norm;
    reg [7:0]  exp;
    reg [22:0] mant;

    integer i;
    integer msb;
    integer shift;
    integer exp_i;

    assign fp_out = fp_r;

    always @* begin
        fp_r  = 32'h00000000;
        sign  = 1'b0;
        mag   = 48'd0;
        norm  = 48'd0;
        exp   = 8'd0;
        mant  = 23'd0;
        msb   = 0;
        shift = 0;
        exp_i = 0;

        if (q_in == 48'sd0) begin
            fp_r = 32'h00000000;
        end else begin
            sign = q_in[47];

            if (q_in[47])
                mag = (~q_in) + 48'd1;
            else
                mag = q_in[47:0];

            for (i = 0; i < 48; i = i + 1) begin
                if (mag[i])
                    msb = i;
            end

            exp_i = msb - 16 + 127;

            if (msb >= 23) begin
                shift = msb - 23;
                norm = mag >> shift;
            end else begin
                shift = 23 - msb;
                norm = mag << shift;
            end

            exp  = exp_i[7:0];
            mant = norm[22:0];
            fp_r = {sign, exp, mant};
        end
    end
endmodule