`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W  = DATA_W + GAIN_W;
    localparam PROD_W = DATA_W + 16;
    localparam ACC_W  = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] sample_now [0:TAP_CNT-1];
    wire signed [15:0]       coeff      [0:TAP_CNT-1];
    wire signed [PROD_W-1:0] product     [0:TAP_CNT-1];
    wire [TAP_CNT*PROD_W-1:0] product_bus;
    wire signed [ACC_W-1:0]  acc_sum;
    wire signed [OUT_W-1:0]  scaled_out;

    integer i;

    assign sample_now[0] = $signed(data_in);

    genvar g;
    generate
        for (g = 1; g < TAP_CNT; g = g + 1) begin : gen_sample_taps
            assign sample_now[g] = delay_line[g-1];
        end

        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_fir_taps
            bpf_coeff_rom u_coeff_rom (
                .tap_index(g[7:0]),
                .coeff(coeff[g])
            );

            bpf_tap_multiply #(
                .DATA_W(DATA_W),
                .COEFF_W(16)
            ) u_tap_multiply (
                .sample(sample_now[g]),
                .coeff(coeff[g]),
                .product(product[g])
            );

            assign product_bus[g*PROD_W +: PROD_W] = product[g];
        end
    endgenerate

    bpf_accumulate #(
        .TAP_CNT(TAP_CNT),
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) u_accumulate (
        .products(product_bus),
        .acc_sum(acc_sum)
    );

    bpf_scale_output #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_scale_output (
        .acc_sum(acc_sum),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                delay_line[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= scaled_out;

                delay_line[0] <= $signed(data_in);
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    delay_line[i] <= delay_line[i-1];
                end
            end
        end
    end
endmodule