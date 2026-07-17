`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output reg signed [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam N = 8;
    localparam ACC_W = DATA_W + COEFF_W + 8;

    reg signed [DATA_W-1:0] sample_buf [0:N-1];
    reg mode_buf;
    reg block_ready;
    reg [2:0] out_idx;
    reg output_active;

    integer i;

    wire signed [ACC_W-1:0] transform_result;
    wire signed [OUT_W-1:0] rounded_result;

    dct1d_8_matrix_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_matrix_mac (
        .mode(mode_buf),
        .out_index(out_idx),
        .x0(sample_buf[0]),
        .x1(sample_buf[1]),
        .x2(sample_buf[2]),
        .x3(sample_buf[3]),
        .x4(sample_buf[4]),
        .x5(sample_buf[5]),
        .x6(sample_buf[6]),
        .x7(sample_buf[7]),
        .acc_out(transform_result)
    );

    dct1d_8_round_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .FRAC_W(10)
    ) u_round_scale (
        .mode(mode_buf),
        .acc_in(transform_result),
        .scaled_out(rounded_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                sample_buf[i] <= {DATA_W{1'b0}};
            mode_buf <= 1'b0;
            block_ready <= 1'b0;
            out_idx <= 3'd0;
            output_active <= 1'b0;
            coeff_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            index_out <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                sample_buf[index] <= sample_in;
                mode_buf <= mode;
                if (index == 3'd7)
                    block_ready <= 1'b1;
            end

            if (block_ready && !output_active) begin
                output_active <= 1'b1;
                out_idx <= 3'd0;
                block_ready <= 1'b0;
            end else if (output_active) begin
                coeff_out <= rounded_result;
                index_out <= out_idx;
                valid_out <= 1'b1;

                if (out_idx == 3'd7) begin
                    output_active <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule