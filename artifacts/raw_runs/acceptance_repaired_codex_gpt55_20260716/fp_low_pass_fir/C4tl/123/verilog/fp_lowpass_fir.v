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

    reg [31:0] sample_hist [0:TAP_CNT-1];
    wire [31:0] next_hist [0:TAP_CNT-1];
    wire [31:0] fir_result;

    reg valid_out_r;
    reg [31:0] data_out_r;

    integer i;

    fp_fir_history_update #(
        .TAP_CNT(TAP_CNT)
    ) u_history_update (
        .valid_in(valid_in),
        .data_in(data_in),
        .hist_in(sample_hist),
        .hist_out(next_hist)
    );

    fp_fir_mac #(
        .TAP_CNT(TAP_CNT)
    ) u_mac (
        .samples(next_hist),
        .result(fir_result)
    );

    fp_fir_output_select u_output_select (
        .valid_in(valid_in),
        .fir_value(fir_result),
        .data_out(data_out)
    );

    assign valid_out = valid_out_r;
    assign data_out = data_out_r;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_hist[i] <= 32'h00000000;
            valid_out_r <= 1'b0;
            data_out_r <= 32'h00000000;
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                for (i = 0; i < TAP_CNT; i = i + 1)
                    sample_hist[i] <= next_hist[i];
                data_out_r <= fir_result;
            end else begin
                data_out_r <= 32'h00000000;
            end
        end
    end

endmodule