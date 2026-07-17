`timescale 1ns/1ps

module fp_mul_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);
    reg sign;
    reg [7:0] ea, eb;
    reg [7:0] exp_bits;
    reg [22:0] fa, fb;
    reg [23:0] ma, mb;
    reg [47:0] prod;

    integer exp_a;
    integer exp_b;
    integer exp_out;
    integer shift;
    integer i;
    integer msb;

    reg [24:0] mant;

    always @* begin
        sign = a[31] ^ b[31];
        ea = a[30:23];
        eb = b[30:23];
        fa = a[22:0];
        fb = b[22:0];

        if ((ea == 8'd0 && fa == 23'd0) || (eb == 8'd0 && fb == 23'd0)) begin
            y = 32'h00000000;
        end else if (ea == 8'hff || eb == 8'hff) begin
            y = {sign, 8'hff, 23'h000000};
        end else begin
            if (ea == 8'd0) begin
                exp_a = -126;
                ma = {1'b0, fa};
            end else begin
                exp_a = ea - 127;
                ma = {1'b1, fa};
            end

            if (eb == 8'd0) begin
                exp_b = -126;
                mb = {1'b0, fb};
            end else begin
                exp_b = eb - 127;
                mb = {1'b1, fb};
            end

            prod = ma * mb;

            msb = 0;
            for (i = 47; i >= 0; i = i - 1) begin
                if (prod[i] && msb == 0)
                    msb = i;
            end

            exp_out = exp_a + exp_b + msb - 46;

            if (exp_out > 127) begin
                y = {sign, 8'hfe, 23'h7fffff};
            end else if (exp_out < -126) begin
                shift = -(exp_a + exp_b + 103);

                if (shift >= 48) begin
                    y = 32'h00000000;
                end else begin
                    if (shift <= 0)
                        mant = (prod << (-shift))[24:0];
                    else
                        mant = (prod >> shift)[24:0];

                    if (mant[22:0] == 23'd0)
                        y = 32'h00000000;
                    else
                        y = {sign, 8'd0, mant[22:0]};
                end
            end else begin
                shift = msb - 23;

                if (shift > 0)
                    mant = prod >> shift;
                else
                    mant = prod << (-shift);

                exp_bits = exp_out + 127;
                y = {sign, exp_bits, mant[22:0]};
            end
        end
    end
endmodule