`timescale 1ns/1ps

module fp32_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);
    wire [31:0] aa = (^a === 1'bx) ? 32'h00000000 : a;
    wire [31:0] bb = (^b === 1'bx) ? 32'h00000000 : b;

    wire sa = aa[31];
    wire sb = bb[31];
    wire [7:0] ea = aa[30:23];
    wire [7:0] eb = bb[30:23];
    wire [22:0] fa = aa[22:0];
    wire [22:0] fb = bb[22:0];

    wire zero = (aa[30:0] == 31'd0) || (bb[30:0] == 31'd0);
    wire sign = sa ^ sb;

    wire [23:0] ma = (ea == 8'd0) ? {1'b0, fa} : {1'b1, fa};
    wire [23:0] mb = (eb == 8'd0) ? {1'b0, fb} : {1'b1, fb};

    wire [47:0] raw_prod = ma * mb;

    wire norm = raw_prod[47];
    wire [47:0] prod_n = norm ? raw_prod : (raw_prod << 1);

    wire signed [10:0] exp_base =
        $signed({3'b000, ea}) + $signed({3'b000, eb}) - 11'sd127 +
        (norm ? 11'sd1 : 11'sd0);

    wire [24:0] mant_pre = {1'b0, prod_n[46:23]};
    wire guard = prod_n[22];
    wire round_bit = prod_n[21];
    wire sticky = |prod_n[20:0];

    wire inc = guard & (round_bit | sticky | mant_pre[0]);
    wire [24:0] mant_round = mant_pre + {24'd0, inc};

    wire carry = mant_round[24];
    wire signed [10:0] exp_round =
        exp_base + (carry ? 11'sd1 : 11'sd0);

    wire [22:0] frac =
        carry ? mant_round[23:1] : mant_round[22:0];

    assign y =
        zero                    ? 32'h00000000 :
        (raw_prod == 48'd0)     ? 32'h00000000 :
        (exp_round >= 11'sd255) ? {sign, 8'hfe, 23'h7fffff} :
        (exp_round <= 11'sd0)   ? 32'h00000000 :
                                  {sign, exp_round[7:0], frac};

endmodule