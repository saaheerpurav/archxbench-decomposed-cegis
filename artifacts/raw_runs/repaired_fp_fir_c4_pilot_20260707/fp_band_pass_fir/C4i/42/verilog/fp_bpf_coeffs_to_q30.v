`timescale 1ns/1ps

module fp_bpf_coeffs_to_q30 #(
    parameter TAP_CNT = 63,
    parameter COEFF_W = 48
) (
    input  [TAP_CNT*32-1:0]      coeffs_fp_flat,
    output [TAP_CNT*COEFF_W-1:0] coeffs_q_flat
);

    genvar i;
    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_COEFF_Q
            fp_bpf_fp32_to_q30 #(
                .COEFF_W(COEFF_W)
            ) coeff_convert_i (
                .fp_in (coeffs_fp_flat[i*32 +: 32]),
                .q_out(coeffs_q_flat[i*COEFF_W +: COEFF_W])
            );
        end
    endgenerate

endmodule


module fp_bpf_fp32_to_q30 #(
    parameter COEFF_W = 48
) (
    input  [31:0] fp_in,
    output signed [COEFF_W-1:0] q_out
);

    wire        sign = fp_in[31];
    wire [7:0]  exp  = fp_in[30:23];
    wire [22:0] frac = fp_in[22:0];
    wire [23:0] mant = (exp == 8'd0) ? {1'b0, frac} : {1'b1, frac};

    reg [63:0] mag;
    reg signed [COEFF_W-1:0] q_r;
    integer sh;

    wire signed [COEFF_W-1:0] sat_pos = {1'b0, {COEFF_W-1{1'b1}}};
    wire signed [COEFF_W-1:0] sat_neg = -sat_pos;

    assign q_out = q_r;

    always @* begin
        mag = 64'd0;
        sh  = 0;

        if (exp == 8'd0 && frac == 23'd0) begin
            q_r = {COEFF_W{1'b0}};
        end else if (exp == 8'hff) begin
            q_r = sign ? sat_neg : sat_pos;
        end else begin
            if (exp == 8'd0)
                sh = -119;
            else begin
                sh = exp;
                sh = sh - 127 + 7;
            end

            if (sh >= 0)
                mag = {40'd0, mant} << sh;
            else if (sh > -64)
                mag = {40'd0, mant} >> (-sh);
            else
                mag = 64'd0;

            if (mag[63:COEFF_W-1] != 0)
                q_r = sign ? sat_neg : sat_pos;
            else
                q_r = sign ? -$signed(mag[COEFF_W-1:0])
                           :  $signed(mag[COEFF_W-1:0]);
        end
    end

endmodule