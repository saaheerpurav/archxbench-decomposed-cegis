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

    localparam ACC_W = DATA_W + COEFF_W + 4;

    reg signed [DATA_W-1:0] sample_buf0;
    reg signed [DATA_W-1:0] sample_buf1;
    reg signed [DATA_W-1:0] sample_buf2;
    reg signed [DATA_W-1:0] sample_buf3;
    reg signed [DATA_W-1:0] sample_buf4;
    reg signed [DATA_W-1:0] sample_buf5;
    reg signed [DATA_W-1:0] sample_buf6;
    reg signed [DATA_W-1:0] sample_buf7;

    reg pending_block;
    reg compute_active;
    reg compute_mode;
    reg [2:0] compute_index;

    wire block_done = valid_in && (index == 3'd7);

    wire signed [DATA_W-1:0] in_s = sample_in;

    wire signed [COEFF_W-1:0] c0;
    wire signed [COEFF_W-1:0] c1;
    wire signed [COEFF_W-1:0] c2;
    wire signed [COEFF_W-1:0] c3;
    wire signed [COEFF_W-1:0] c4;
    wire signed [COEFF_W-1:0] c5;
    wire signed [COEFF_W-1:0] c6;
    wire signed [COEFF_W-1:0] c7;

    wire signed [ACC_W-1:0] mac_sum;
    wire signed [OUT_W-1:0] rounded_out;

    reg signed [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    dct_coeff_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .mode(compute_mode),
        .out_index(compute_index),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    dct_mac8 #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac8 (
        .x0(sample_buf0),
        .x1(sample_buf1),
        .x2(sample_buf2),
        .x3(sample_buf3),
        .x4(sample_buf4),
        .x5(sample_buf5),
        .x6(sample_buf6),
        .x7(sample_buf7),
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

    dct_round_clip #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .FRAC_W(14)
    ) u_round_clip (
        .sum(mac_sum),
        .out(rounded_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_buf0 <= 0;
            sample_buf1 <= 0;
            sample_buf2 <= 0;
            sample_buf3 <= 0;
            sample_buf4 <= 0;
            sample_buf5 <= 0;
            sample_buf6 <= 0;
            sample_buf7 <= 0;
            pending_block <= 1'b0;
            compute_active <= 1'b0;
            compute_mode <= 1'b0;
            compute_index <= 3'd0;
            coeff_out_r <= 0;
            valid_out_r <= 1'b0;
            index_out_r <= 3'd0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in) begin
                case (index)
                    3'd0: sample_buf0 <= in_s;
                    3'd1: sample_buf1 <= in_s;
                    3'd2: sample_buf2 <= in_s;
                    3'd3: sample_buf3 <= in_s;
                    3'd4: sample_buf4 <= in_s;
                    3'd5: sample_buf5 <= in_s;
                    3'd6: sample_buf6 <= in_s;
                    3'd7: sample_buf7 <= in_s;
                    default: sample_buf0 <= sample_buf0;
                endcase
            end

            if (block_done) begin
                pending_block <= 1'b1;
            end

            if (!compute_active && (pending_block || block_done)) begin
                compute_active <= 1'b1;
                compute_mode <= mode;
                compute_index <= 3'd0;
                pending_block <= 1'b0;
            end else if (compute_active) begin
                coeff_out_r <= rounded_out;
                valid_out_r <= 1'b1;
                index_out_r <= compute_index;

                if (compute_index == 3'd7) begin
                    compute_active <= 1'b0;
                    compute_index <= 3'd0;
                end else begin
                    compute_index <= compute_index + 3'd1;
                end
            end
        end
    end

endmodule