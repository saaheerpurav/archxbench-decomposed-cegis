`timescale 1ns/1ps

module fp_bpf_mac_tree #(
    parameter TAP_CNT  = 63,
    parameter SAMPLE_W = 48,
    parameter COEFF_W  = 48,
    parameter ACC_W    = 48
) (
    input  [TAP_CNT*SAMPLE_W-1:0] samples_q_flat,
    input  [TAP_CNT*COEFF_W-1:0]  coeffs_q_flat,
    output signed [ACC_W-1:0]     acc_q
);
    localparam PROD_W = SAMPLE_W + COEFF_W;
    localparam SUM_W  = PROD_W + 8;

    integer i;

    reg signed [SAMPLE_W-1:0] sample_i;
    reg signed [COEFF_W-1:0]  coeff_i;
    reg signed [PROD_W-1:0]   product;
    reg signed [SUM_W-1:0]    shifted_product;
    reg signed [SUM_W-1:0]    sum;
    reg signed [ACC_W-1:0]    acc_r;

    wire signed [SUM_W-1:0] acc_max;
    wire signed [SUM_W-1:0] acc_min;

    assign acc_max = {{(SUM_W-ACC_W){1'b0}}, 1'b0, {(ACC_W-1){1'b1}}};
    assign acc_min = {{(SUM_W-ACC_W){1'b1}}, 1'b1, {(ACC_W-1){1'b0}}};

    assign acc_q = acc_r;

    always @* begin
        sum = {SUM_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample_i = $signed(samples_q_flat[i*SAMPLE_W +: SAMPLE_W]);
            coeff_i  = $signed(coeffs_q_flat[i*COEFF_W +: COEFF_W]);

            product = sample_i * coeff_i;
            shifted_product = $signed(product) >>> 30;
            sum = sum + shifted_product;
        end

        if (sum > acc_max)
            acc_r = {1'b0, {(ACC_W-1){1'b1}}};
        else if (sum < acc_min)
            acc_r = {1'b1, {(ACC_W-1){1'b0}}};
        else
            acc_r = sum[ACC_W-1:0];
    end
endmodule