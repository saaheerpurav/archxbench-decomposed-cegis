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

    reg signed [DATA_W-1:0] sample_mem [0:7];
    reg block_pending;
    reg output_active;
    reg [2:0] output_index;
    reg block_mode;

    wire signed [DATA_W-1:0] in_signed;
    assign in_signed = sample_in;

    wire signed [DATA_W-1:0] x0 = (valid_in && index == 3'd0) ? in_signed : sample_mem[0];
    wire signed [DATA_W-1:0] x1 = (valid_in && index == 3'd1) ? in_signed : sample_mem[1];
    wire signed [DATA_W-1:0] x2 = (valid_in && index == 3'd2) ? in_signed : sample_mem[2];
    wire signed [DATA_W-1:0] x3 = (valid_in && index == 3'd3) ? in_signed : sample_mem[3];
    wire signed [DATA_W-1:0] x4 = (valid_in && index == 3'd4) ? in_signed : sample_mem[4];
    wire signed [DATA_W-1:0] x5 = (valid_in && index == 3'd5) ? in_signed : sample_mem[5];
    wire signed [DATA_W-1:0] x6 = (valid_in && index == 3'd6) ? in_signed : sample_mem[6];
    wire signed [DATA_W-1:0] x7 = (valid_in && index == 3'd7) ? in_signed : sample_mem[7];

    wire [2:0] transform_row;
    assign transform_row = output_index;

    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;

    dct1d_8_coeff_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .mode(block_mode),
        .row(transform_row),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    wire signed [DATA_W+COEFF_W+3:0] mac_sum;

    dct1d_8_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(DATA_W+COEFF_W+4)
    ) u_mac (
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .x4(x4),
        .x5(x5),
        .x6(x6),
        .x7(x7),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7),
        .sum(mac_sum)
    );

    wire signed [OUT_W-1:0] scaled_result;

    dct1d_8_round_sat #(
        .IN_W(DATA_W+COEFF_W+4),
        .OUT_W(OUT_W),
        .FRAC_W(14)
    ) u_round_sat (
        .in_value(mac_sum),
        .out_value(scaled_result)
    );

    reg signed [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    always @(posedge clk) begin
        if (rst) begin
            sample_mem[0] <= {DATA_W{1'b0}};
            sample_mem[1] <= {DATA_W{1'b0}};
            sample_mem[2] <= {DATA_W{1'b0}};
            sample_mem[3] <= {DATA_W{1'b0}};
            sample_mem[4] <= {DATA_W{1'b0}};
            sample_mem[5] <= {DATA_W{1'b0}};
            sample_mem[6] <= {DATA_W{1'b0}};
            sample_mem[7] <= {DATA_W{1'b0}};
            block_pending <= 1'b0;
            output_active <= 1'b0;
            output_index <= 3'd0;
            block_mode <= 1'b0;
            coeff_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            index_out_r <= 3'd0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in) begin
                sample_mem[index] <= in_signed;
                if (index == 3'd7) begin
                    block_pending <= 1'b1;
                    block_mode <= mode;
                end
            end

            if (output_active) begin
                coeff_out_r <= scaled_result;
                index_out_r <= output_index;
                valid_out_r <= 1'b1;

                if (output_index == 3'd7) begin
                    output_active <= 1'b0;
                    output_index <= 3'd0;
                end else begin
                    output_index <= output_index + 3'd1;
                end
            end else if (block_pending) begin
                block_pending <= 1'b0;
                output_active <= 1'b1;
                output_index <= 3'd0;
            end
        end
    end

endmodule