`timescale 1ns/1ps

module fp_add_normalize (
    input in_sign,
    input [7:0] in_exp,
    input [27:0] in_sum,
    input in_zero,
    output reg out_sign,
    output reg [8:0] out_exp,
    output reg [26:0] out_sig,
    output reg out_zero
);

integer i;
reg [27:0] work;
reg [8:0] exp_work;

always @* begin
    out_sign = in_sign;
    out_zero = in_zero || (in_sum == 28'b0);
    out_exp = {1'b0, in_exp};
    out_sig = 27'b0;

    work = in_sum;
    exp_work = {1'b0, in_exp};

    if (out_zero) begin
        out_sign = 1'b0;
        out_exp = 9'b0;
        out_sig = 27'b0;
    end else if (work[27]) begin
        out_exp = exp_work + 9'd1;
        out_sig = work[27:1];

        // Preserve sticky information when the carry normalization
        // discards bit 0.
        out_sig[0] = work[1] | work[0];
    end else begin
        for (i = 0; i < 26; i = i + 1) begin
            if (!work[26] && (exp_work > 9'd1)) begin
                work = work << 1;
                exp_work = exp_work - 9'd1;
            end
        end

        out_exp = exp_work;
        out_sig = work[26:0];
    end
end

endmodule