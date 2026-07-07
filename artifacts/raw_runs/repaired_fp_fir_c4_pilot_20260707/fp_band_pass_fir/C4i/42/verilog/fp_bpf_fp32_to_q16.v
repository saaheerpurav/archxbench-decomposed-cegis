`timescale 1ns/1ps

module fp_bpf_fp32_to_q16 (
    input  [31:0] fp_in,
    output signed [47:0] q_out
);
    localparam signed [47:0] SAT_POS = 48'sh7fffffffffff;
    localparam signed [47:0] SAT_NEG = 48'sh800000000000;

    wire        sign = fp_in[31];
    wire [7:0]  exp  = fp_in[30:23];
    wire [22:0] frac = fp_in[22:0];

    wire [23:0] mant = (exp == 8'd0) ? {1'b0, frac} : {1'b1, frac};

    reg [63:0] mag;
    reg signed [47:0] q_r;
    integer sh;

    assign q_out = q_r;

    always @* begin
        mag = 64'd0;
        q_r = 48'sd0;
        sh  = 0;

        if ((exp == 8'd0) && (frac == 23'd0)) begin
            q_r = 48'sd0;
        end else if (exp == 8'hff) begin
            q_r = sign ? SAT_NEG : SAT_POS;
        end else begin
            sh = $signed({1'b0, exp}) - 9'sd134;

            if (sh >= 0) begin
                if (sh >= 40)
                    mag = 64'hffffffffffffffff;
                else
                    mag = {40'd0, mant} << sh;
            end else begin
                if (sh <= -64)
                    mag = 64'd0;
                else
                    mag = {40'd0, mant} >> (-sh);
            end

            if (!sign) begin
                if (mag[63:47] != 17'd0)
                    q_r = SAT_POS;
                else
                    q_r = $signed(mag[47:0]);
            end else begin
                if (mag >= 64'h0000800000000000)
                    q_r = SAT_NEG;
                else
                    q_r = -$signed({1'b0, mag[46:0]});
            end
        end
    end
endmodule