module fp_add_unpack (
    input  [31:0] a,
    input  [31:0] b,
    output        sign_a,
    output        sign_b,
    output [7:0]  exp_a,
    output [7:0]  exp_b,
    output [26:0] mant_a,
    output [26:0] mant_b,
    output        zero_a,
    output        zero_b,
    output        inf_a,
    output        inf_b,
    output        nan_a,
    output        nan_b
);

wire [7:0]  raw_exp_a;
wire [7:0]  raw_exp_b;
wire [22:0] frac_a;
wire [22:0] frac_b;

assign raw_exp_a = a[30:23];
assign raw_exp_b = b[30:23];
assign frac_a    = a[22:0];
assign frac_b    = b[22:0];

assign sign_a = a[31];
assign sign_b = b[31];

assign zero_a = (raw_exp_a == 8'h00) && (frac_a == 23'd0);
assign zero_b = (raw_exp_b == 8'h00) && (frac_b == 23'd0);

assign inf_a = (raw_exp_a == 8'hff) && (frac_a == 23'd0);
assign inf_b = (raw_exp_b == 8'hff) && (frac_b == 23'd0);

assign nan_a = (raw_exp_a == 8'hff) && (frac_a != 23'd0);
assign nan_b = (raw_exp_b == 8'hff) && (frac_b != 23'd0);

assign exp_a = (raw_exp_a == 8'h00) ? 8'd1 : raw_exp_a;
assign exp_b = (raw_exp_b == 8'h00) ? 8'd1 : raw_exp_b;

assign mant_a = (raw_exp_a == 8'h00) ? {1'b0, frac_a, 3'b000}
                                     : {1'b1, frac_a, 3'b000};

assign mant_b = (raw_exp_b == 8'h00) ? {1'b0, frac_b, 3'b000}
                                     : {1'b1, frac_b, 3'b000};

endmodule