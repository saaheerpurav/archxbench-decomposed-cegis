`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    localparam SAMPLE_W = 48;
    localparam COEFF_W  = 48;
    localparam ACC_W    = 48;

    reg [31:0] sample_shift [0:TAP_CNT-1];
    reg [15:0] valid_count;
    reg        valid_out_r;
    reg [31:0] data_out_r;

    wire signed [SAMPLE_W-1:0] data_in_q;
    wire [TAP_CNT*32-1:0] coeffs_fp_flat;
    wire [TAP_CNT*COEFF_W-1:0] coeffs_q_flat;
    wire [TAP_CNT*SAMPLE_W-1:0] samples_q_flat;
    wire signed [ACC_W-1:0] fir_acc_q;
    wire [31:0] fir_fp;

    integer i;

    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

    fp_bpf_fp32_to_q16 data_in_convert (
        .fp_in(data_in),
        .q_out(data_in_q)
    );

    fp_bpf_coeff_rom #(
        .TAP_CNT(TAP_CNT)
    ) coeff_rom_i (
        .coeffs_fp_flat(coeffs_fp_flat)
    );

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : GEN_SAMPLE_CONVERT
            wire signed [SAMPLE_W-1:0] sample_q;
            fp_bpf_fp32_to_q16 sample_convert_i (
                .fp_in(sample_shift[g]),
                .q_out(sample_q)
            );
            assign samples_q_flat[g*SAMPLE_W +: SAMPLE_W] = sample_q;
        end
    endgenerate

    fp_bpf_coeffs_to_q30 #(
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W)
    ) coeff_convert_i (
        .coeffs_fp_flat(coeffs_fp_flat),
        .coeffs_q_flat(coeffs_q_flat)
    );

    fp_bpf_mac_tree #(
        .TAP_CNT(TAP_CNT),
        .SAMPLE_W(SAMPLE_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) mac_tree_i (
        .samples_q_flat(samples_q_flat),
        .coeffs_q_flat(coeffs_q_flat),
        .acc_q(fir_acc_q)
    );

    fp_bpf_q16_to_fp32 result_convert_i (
        .q_in(fir_acc_q),
        .fp_out(fir_fp)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_shift[i] <= 32'h00000000;
            valid_count <= 16'd0;
            valid_out_r <= 1'b0;
            data_out_r  <= 32'h00000000;
        end else begin
            if (valid_in) begin
                sample_shift[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_shift[i] <= sample_shift[i-1];

                if (valid_count < TAP_CNT[15:0])
                    valid_count <= valid_count + 16'd1;
            end

            valid_out_r <= valid_in && (valid_count >= (TAP_CNT-1));
            data_out_r  <= fir_fp;
        end
    end

endmodule