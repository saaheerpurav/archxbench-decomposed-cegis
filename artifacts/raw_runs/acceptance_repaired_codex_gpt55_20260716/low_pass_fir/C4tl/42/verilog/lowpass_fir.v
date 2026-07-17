`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output reg                  valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];
    wire signed [DATA_W-1:0] next_samples [0:TAP_CNT-1];
    wire [TAP_CNT*DATA_W-1:0] sample_flat;
    wire signed [63:0] acc_q15;
    wire signed [OUT_W-1:0] scaled_out;

    integer i;

    assign next_samples[0] = $signed(data_in);

    genvar g;
    generate
        for (g = 1; g < TAP_CNT; g = g + 1) begin : gen_next_samples
            assign next_samples[g] = delay_line[g-1];
        end

        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_sample_flat
            assign sample_flat[g*DATA_W +: DATA_W] = next_samples[g];
        end
    endgenerate

    fir_symmetric_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_mac (
        .sample_flat(sample_flat),
        .acc(acc_q15)
    );

    fir_output_scale #(
        .OUT_W(OUT_W)
    ) u_scale (
        .acc(acc_q15),
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
                for (i = TAP_CNT-1; i > 0; i = i - 1) begin
                    delay_line[i] <= delay_line[i-1];
                end
                delay_line[0] <= $signed(data_in);
            end
        end
    end
endmodule