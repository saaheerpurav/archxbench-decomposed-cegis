module fp_add_round_pack (
    input sign_in,
    input [8:0] exp_in,
    input [27:0] mant_in,
    input zero_in,
    input overflow_in,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    input eff_sign_b,
    output reg [31:0] result
);

reg [8:0] exp_r;
reg [24:0] rounded;
reg guard_bit;
reg round_bit;
reg sticky_bit;
reg lsb_bit;
reg increment;

always @* begin
    result = 32'h00000000;

    exp_r = exp_in;

    guard_bit = mant_in[2];
    round_bit = mant_in[1];
    sticky_bit = mant_in[0];
    lsb_bit = mant_in[3];

    increment = guard_bit && (round_bit || sticky_bit || lsb_bit);
    rounded = {1'b0, mant_in[26:3]} + {24'd0, increment};

    if (nan_a || nan_b || (inf_a && inf_b && (sign_in != eff_sign_b))) begin
        result = 32'h7FC00000;
    end else if (inf_a) begin
        result = {sign_in, 8'hFF, 23'd0};
    end else if (inf_b) begin
        result = {eff_sign_b, 8'hFF, 23'd0};
    end else if (zero_in) begin
        result = 32'h00000000;
    end else if (overflow_in) begin
        result = {sign_in, 8'hFF, 23'd0};
    end else begin
        if (rounded[24]) begin
            rounded = rounded >> 1;
            exp_r = exp_r + 9'd1;
        end

        if (exp_r >= 9'd255) begin
            result = {sign_in, 8'hFF, 23'd0};
        end else if (exp_r == 9'd0) begin
            result = {sign_in, 31'd0};
        end else begin
            result = {sign_in, exp_r[7:0], rounded[22:0]};
        end
    end
end

endmodule