`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);
    integer i;

    reg [31:0] x_hist [0:TAP_CNT-1];
    reg [31:0] data_out_r;
    reg valid_out_r;

    wire [31:0] sample [0:TAP_CNT-1];
    wire [31:0] coeff  [0:TAP_CNT-1];
    wire [31:0] prod   [0:TAP_CNT-1];
    wire [31:0] sum    [0:TAP_CNT];

    assign valid_out = valid_out_r;
    assign data_out = data_out_r;
    assign sum[0] = 32'h00000000;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : fir_taps
            assign sample[g] = (g == 0) ? data_in : x_hist[g-1];

            fp_hp_coeff_rom u_coeff (
                .idx(g[7:0]),
                .coeff(coeff[g])
            );

            fp32_mul u_mul (
                .a(sample[g]),
                .b(coeff[g]),
                .y(prod[g])
            );

            fp32_add u_add (
                .a(sum[g]),
                .b(prod[g]),
                .y(sum[g+1])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                x_hist[i] <= 32'h00000000;
            data_out_r <= 32'h00000000;
            valid_out_r <= 1'b0;
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                data_out_r <= sum[TAP_CNT];
                x_hist[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    x_hist[i] <= x_hist[i-1];
            end
        end
    end
endmodule