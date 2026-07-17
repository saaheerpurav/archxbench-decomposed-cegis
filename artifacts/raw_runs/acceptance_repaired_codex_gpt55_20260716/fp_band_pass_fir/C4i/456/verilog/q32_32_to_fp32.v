`timescale 1ns/1ps

module q32_32_to_fp32 (
    input  wire signed [63:0] q,
    output reg  [31:0] fp
);
    reg sign;
    reg [63:0] mag;
    reg [63:0] norm;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [24:0] rounded;
    reg guard;
    reg sticky;
    integer msb;
    integer shift;
    integer i;

    always @* begin
        fp = 32'h00000000;

        if (q != 64'sd0) begin
            sign = q[63];
            mag = sign ? (~q + 64'd1) : q[63:0];

            msb = 0;
            for (i = 0; i < 64; i = i + 1) begin
                if (mag[i])
                    msb = i;
            end

            exp = msb - 32 + 127;
            frac = 23'd0;

            if (msb >= 23) begin
                shift = msb - 23;
                norm = mag >> shift;

                guard = 1'b0;
                sticky = 1'b0;

                if (shift > 0) begin
                    guard = mag[shift - 1];
                    for (i = 0; i < shift - 1; i = i + 1)
                        sticky = sticky | mag[i];
                end

                rounded = {1'b0, norm[23:0]} +
                          {24'd0, (guard & (sticky | norm[0]))};

                if (rounded[24]) begin
                    exp = exp + 8'd1;
                    frac = rounded[23:1];
                end else begin
                    frac = rounded[22:0];
                end
            end else begin
                norm = mag << (23 - msb);
                frac = norm[22:0];
            end

            if (exp >= 8'hff)
                fp = {sign, 8'hfe, 23'h7fffff};
            else
                fp = {sign, exp, frac};
        end
    end
endmodule