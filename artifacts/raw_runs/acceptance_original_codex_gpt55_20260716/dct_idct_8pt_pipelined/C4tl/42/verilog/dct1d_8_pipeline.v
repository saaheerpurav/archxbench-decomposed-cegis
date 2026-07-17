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
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    reg signed [DATA_W-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    reg [2:0] sample_count;
    reg block_ready;
    reg out_active;
    reg [2:0] out_idx;
    reg mode_block;

    wire signed [OUT_W-1:0] transform_value;

    dct1d_8_matrix_core #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .OUT_W(OUT_W)
    ) u_matrix_core (
        .mode(mode_block),
        .out_index(out_idx),
        .x0(x0), .x1(x1), .x2(x2), .x3(x3),
        .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .y(transform_value)
    );

    assign coeff_out = transform_value;
    assign valid_out = out_active;
    assign index_out = out_idx;

    always @(posedge clk) begin
        if (rst) begin
            x0 <= 0;
            x1 <= 0;
            x2 <= 0;
            x3 <= 0;
            x4 <= 0;
            x5 <= 0;
            x6 <= 0;
            x7 <= 0;
            sample_count <= 0;
            block_ready <= 1'b0;
            out_active <= 1'b0;
            out_idx <= 0;
            mode_block <= 1'b0;
        end else begin
            block_ready <= 1'b0;

            if (valid_in) begin
                case (index)
                    3'd0: x0 <= sample_in;
                    3'd1: x1 <= sample_in;
                    3'd2: x2 <= sample_in;
                    3'd3: x3 <= sample_in;
                    3'd4: x4 <= sample_in;
                    3'd5: x5 <= sample_in;
                    3'd6: x6 <= sample_in;
                    3'd7: x7 <= sample_in;
                    default: x0 <= x0;
                endcase

                if (sample_count == 3'd7 || index == 3'd7) begin
                    sample_count <= 0;
                    block_ready <= 1'b1;
                    mode_block <= mode;
                end else begin
                    sample_count <= sample_count + 3'd1;
                end
            end

            if (out_active) begin
                if (out_idx == 3'd7) begin
                    out_active <= 1'b0;
                    out_idx <= 0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end else if (block_ready) begin
                out_active <= 1'b1;
                out_idx <= 0;
            end
        end
    end

endmodule