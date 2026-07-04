module fp_add_normalize (
    input sign_in,
    input [7:0] exp_in,
    input [27:0] mant_in,
    input zero_in,
    input inf_a_in,
    input inf_b_in,
    input nan_a_in,
    input nan_b_in,
    input eff_sign_b_in,
    output reg sign_out,
    output reg [8:0] exp_out,
    output reg [27:0] mant_out,
    output reg zero_out,
    output reg overflow_out,
    output inf_a,
    output inf_b,
    output nan_a,
    output nan_b,
    output eff_sign_b
);

integer i;
reg [8:0] exp_norm;
reg [27:0] mant_norm;

assign inf_a = inf_a_in;
assign inf_b = inf_b_in;
assign nan_a = nan_a_in;
assign nan_b = nan_b_in;
assign eff_sign_b = eff_sign_b_in;

always @* begin
    sign_out = sign_in;
    zero_out = zero_in;
    overflow_out = 1'b0;

    exp_norm = {1'b0, exp_in};
    mant_norm = mant_in;

    if (zero_in || mant_in == 28'd0) begin
        zero_out = 1'b1;
        exp_norm = 9'd0;
        mant_norm = 28'd0;
    end else begin
        if (mant_norm[27]) begin
            mant_norm = {1'b0, mant_norm[27:1] | {27'd0, mant_norm[0]}};
            exp_norm = exp_norm + 9'd1;
        end else begin
            for (i = 0; i < 27; i = i + 1) begin
                if (!mant_norm[26] && exp_norm > 9'd0) begin
                    mant_norm = mant_norm << 1;
                    exp_norm = exp_norm - 9'd1;
                end
            end
        end

        if (exp_norm >= 9'd255) begin
            overflow_out = 1'b1;
        end
    end

    exp_out = exp_norm;
    mant_out = mant_norm;
end

endmodule