`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

    reg [TAP_CNT*32-1:0] sample_window;
    reg valid_q;
    reg [31:0] data_q;

    wire [TAP_CNT*32-1:0] coeff_words;
    wire [31:0] fir_y;
    wire valid_next;

    fp_bpf_coeff_rom #(.TAP_CNT(TAP_CNT)) u_coeff_rom (
        .coeff_words(coeff_words)
    );

    fp_bpf_mac_comb #(.TAP_CNT(TAP_CNT)) u_mac (
        .samples(sample_window),
        .coeffs(coeff_words),
        .result(fir_y)
    );

    fp_bpf_valid_gate u_valid_gate (
        .valid_in(valid_in),
        .valid_out(valid_next)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_window <= {TAP_CNT*32{1'b0}};
            valid_q <= 1'b0;
            data_q <= 32'h00000000;
        end else begin
            valid_q <= valid_next;
            if (valid_in) begin
                sample_window <= {sample_window[(TAP_CNT-1)*32-1:0], data_in};
                data_q <= fir_y;
            end else begin
                data_q <= 32'h00000000;
            end
        end
    end

    assign valid_out = valid_q;
    assign data_out = data_q;

endmodule