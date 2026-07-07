`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT    = 31,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output                  valid_out,
    output  [31:0]          data_out
);

    reg  [31:0] taps [0:TAP_CNT-1];
    reg  [31:0] data_out_r;
    reg         valid_out_r;
    reg  [15:0] fill_count;
    integer i;

    wire [TAP_CNT*32-1:0] taps_flat;
    wire [TAP_CNT*32-1:0] coeffs_flat;
    wire [31:0]           fir_result;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : FLATTEN_TAPS
            assign taps_flat[g*32 +: 32] = taps[g];
        end
    endgenerate

    fp_highpass_coeff_rom #(
        .TAP_CNT(TAP_CNT)
    ) u_coeff_rom (
        .coeffs_flat(coeffs_flat)
    );

    fp_highpass_mac #(
        .TAP_CNT(TAP_CNT)
    ) u_mac (
        .samples_flat(taps_flat),
        .coeffs_flat (coeffs_flat),
        .result      (fir_result)
    );

    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                taps[i] <= 32'h00000000;
            end
            fill_count  <= 16'd0;
            valid_out_r <= 1'b0;
            data_out_r  <= 32'h00000000;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in) begin
                taps[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    taps[i] <= taps[i-1];
                end

                data_out_r <= fir_result;

                if (fill_count >= (TAP_CNT-1)) begin
                    valid_out_r <= 1'b1;
                end else begin
                    fill_count <= fill_count + 16'd1;
                end
            end
        end
    end

endmodule