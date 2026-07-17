`timescale 1ns/1ps

module fp_add_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);

reg sa, sb, sr, bs, ss, sticky;
reg [7:0] ea, eb, ae, be, se, er;
reg [22:0] fa, fb;
reg [27:0] ma, mb, bm, sm, m, res;
reg [8:0] d;
reg [24:0] rnd;
integer i;

always @* begin
    sa = a[31];
    sb = b[31];
    ea = a[30:23];
    eb = b[30:23];
    fa = a[22:0];
    fb = b[22:0];

    ae = (ea == 8'd0) ? 8'd1 : ea;
    be = (eb == 8'd0) ? 8'd1 : eb;

    ma = (ea == 8'd0) ? {1'b0, fa, 4'd0} : {1'b1, fa, 4'd0};
    mb = (eb == 8'd0) ? {1'b0, fb, 4'd0} : {1'b1, fb, 4'd0};

    if (ea == 8'hff) begin
        y = a;
    end else if (eb == 8'hff) begin
        y = b;
    end else if ((ea == 8'd0) && (fa == 23'd0)) begin
        y = b;
    end else if ((eb == 8'd0) && (fb == 23'd0)) begin
        y = a;
    end else begin
        if ({ae, ma} >= {be, mb}) begin
            er = ae;
            se = be;
            bm = ma;
            sm = mb;
            bs = sa;
            ss = sb;
        end else begin
            er = be;
            se = ae;
            bm = mb;
            sm = ma;
            bs = sb;
            ss = sa;
        end

        d = er - se;
        sticky = 1'b0;

        if (d >= 9'd28) begin
            sticky = (sm != 28'd0);
            sm = 28'd0;
            sm[0] = sticky;
        end else if (d != 9'd0) begin
            for (i = 0; i < 28; i = i + 1)
                if (i < d)
                    sticky = sticky | sm[i];
            sm = sm >> d;
            sm[0] = sm[0] | sticky;
        end

        sr = bs;

        if (bs == ss) begin
            res = bm + sm;
            if (res[27] == 1'b1) begin
                m = res >> 1;
                m[0] = m[0] | res[0];
                er = er + 8'd1;
            end else begin
                m = res;
            end
        end else begin
            res = bm - sm;
            m = res;

            if (m == 28'd0) begin
                er = 8'd0;
                sr = 1'b0;
            end else begin
                for (i = 0; i < 27; i = i + 1) begin
                    if ((m[26] == 1'b0) && (er > 8'd1)) begin
                        m = m << 1;
                        er = er - 8'd1;
                    end
                end
            end
        end

        if (m == 28'd0) begin
            y = 32'h00000000;
        end else begin
            if ((m[3] == 1'b1) && ((m[2:0] != 3'd0) || (m[4] == 1'b1)))
                rnd = {1'b0, m[27:4]} + 25'd1;
            else
                rnd = {1'b0, m[27:4]};

            if (rnd[24] == 1'b1) begin
                rnd = rnd >> 1;
                er = er + 8'd1;
            end

            if (er >= 8'hff)
                y = {sr, 8'hff, 23'd0};
            else
                y = {sr, er, rnd[22:0]};
        end
    end
end

endmodule