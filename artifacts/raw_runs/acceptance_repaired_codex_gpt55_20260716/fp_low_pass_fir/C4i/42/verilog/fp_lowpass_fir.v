`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);
    localparam LATENCY = TAP_CNT - 1;

    reg [31:0] sample_hist [0:TAP_CNT-1];
    reg [31:0] data_pipe [0:LATENCY];
    reg valid_pipe [0:LATENCY];

    wire [31:0] coeff [0:TAP_CNT-1];
    wire [31:0] hist_for_mac [0:TAP_CNT-1];
    wire [31:0] product [0:TAP_CNT-1];
    wire [31:0] sum [0:TAP_CNT-1];

    integer i;

    assign hist_for_mac[0] = data_in;

    genvar gi;
    generate
        for (gi = 1; gi < TAP_CNT; gi = gi + 1) begin : GEN_HIST_WIRE
            assign hist_for_mac[gi] = sample_hist[gi-1];
        end

        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_COEFF_MUL
            fp_fir_coeff_rom u_coeff (
                .addr(gi[7:0]),
                .coeff(coeff[gi])
            );

            fp_mul_comb u_mul (
                .a(hist_for_mac[gi]),
                .b(coeff[gi]),
                .y(product[gi])
            );
        end

        assign sum[0] = product[0];

        for (gi = 1; gi < TAP_CNT; gi = gi + 1) begin : GEN_ADD_CHAIN
            fp_add_comb u_add (
                .a(sum[gi-1]),
                .b(product[gi]),
                .y(sum[gi])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_hist[i] <= 32'h00000000;
            for (i = 0; i <= LATENCY; i = i + 1) begin
                data_pipe[i] <= 32'h00000000;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            if (valid_in) begin
                sample_hist[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_hist[i] <= sample_hist[i-1];
            end

            valid_pipe[0] <= valid_in;
            data_pipe[0] <= valid_in ? sum[TAP_CNT-1] : 32'h00000000;

            for (i = 1; i <= LATENCY; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                data_pipe[i] <= data_pipe[i-1];
            end
        end
    end

    assign valid_out = valid_pipe[LATENCY];
    assign data_out = data_pipe[LATENCY];

endmodule