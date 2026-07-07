`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT    = 31,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output  reg             valid_out,
    output  reg [31:0]      data_out
);

    integer i;
    reg [31:0] delay_line [0:TAP_CNT-1];
    reg [15:0] sample_count;

    wire [31:0] coeff_w  [0:TAP_CNT-1];
    wire [31:0] prod_w   [0:TAP_CNT-1];
    wire [31:0] sum_w    [0:TAP_CNT-1];

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : GEN_TAPS
            fp_hp_coeff_rom u_coeff (
                .index(g[7:0]),
                .coeff(coeff_w[g])
            );

            fp_float_mul_comb u_mul (
                .a(delay_line[g]),
                .b(coeff_w[g]),
                .y(prod_w[g])
            );
        end
    endgenerate

    assign sum_w[0] = prod_w[0];

    generate
        for (g = 1; g < TAP_CNT; g = g + 1) begin : GEN_SUM
            fp_float_add_comb u_add (
                .a(sum_w[g-1]),
                .b(prod_w[g]),
                .y(sum_w[g])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                delay_line[i] <= 32'h00000000;
            end
            sample_count <= 16'd0;
            valid_out    <= 1'b0;
            data_out     <= 32'h00000000;
        end else begin
            if (valid_in) begin
                delay_line[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    delay_line[i] <= delay_line[i-1];
                end

                if (sample_count < TAP_CNT)
                    sample_count <= sample_count + 16'd1;

                valid_out <= (sample_count >= (TAP_CNT-1));
                data_out  <= sum_w[TAP_CNT-1];
            end else begin
                valid_out <= 1'b0;
                data_out  <= sum_w[TAP_CNT-1];
            end
        end
    end

endmodule