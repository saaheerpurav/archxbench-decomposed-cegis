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
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam ACC_W = DATA_W + COEFF_W + 4;
    localparam SHIFT = 14;

    reg signed [DATA_W-1:0] sample_bank [0:7];
    reg block_mode;

    reg active;
    reg [2:0] row_ctr;

    reg signed [DATA_W-1:0] p0_s0, p0_s1, p0_s2, p0_s3;
    reg signed [DATA_W-1:0] p0_s4, p0_s5, p0_s6, p0_s7;
    reg p0_mode;
    reg [2:0] p0_row;
    reg p0_valid;

    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;

    dct1d_8_coeff_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .mode(p0_mode),
        .row(p0_row),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    wire signed [ACC_W-1:0] dot_acc;

    dct1d_8_dot_product #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_dot (
        .s0(p0_s0),
        .s1(p0_s1),
        .s2(p0_s2),
        .s3(p0_s3),
        .s4(p0_s4),
        .s5(p0_s5),
        .s6(p0_s6),
        .s7(p0_s7),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7),
        .acc(dot_acc)
    );

    reg signed [ACC_W-1:0] p1_acc;
    reg [2:0] p1_row;
    reg p1_valid;

    wire signed [OUT_W-1:0] rounded_out;

    dct1d_8_round_sat #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(SHIFT)
    ) u_round_sat (
        .acc(p1_acc),
        .out(rounded_out)
    );

    reg signed [OUT_W-1:0] coeff_out_r;
    reg [2:0] index_out_r;
    reg valid_out_r;

    assign coeff_out = coeff_out_r;
    assign index_out = index_out_r;
    assign valid_out = valid_out_r;

    always @(posedge clk) begin
        if (rst) begin
            sample_bank[0] <= {DATA_W{1'b0}};
            sample_bank[1] <= {DATA_W{1'b0}};
            sample_bank[2] <= {DATA_W{1'b0}};
            sample_bank[3] <= {DATA_W{1'b0}};
            sample_bank[4] <= {DATA_W{1'b0}};
            sample_bank[5] <= {DATA_W{1'b0}};
            sample_bank[6] <= {DATA_W{1'b0}};
            sample_bank[7] <= {DATA_W{1'b0}};
            block_mode <= 1'b0;

            active <= 1'b0;
            row_ctr <= 3'd0;

            p0_s0 <= {DATA_W{1'b0}};
            p0_s1 <= {DATA_W{1'b0}};
            p0_s2 <= {DATA_W{1'b0}};
            p0_s3 <= {DATA_W{1'b0}};
            p0_s4 <= {DATA_W{1'b0}};
            p0_s5 <= {DATA_W{1'b0}};
            p0_s6 <= {DATA_W{1'b0}};
            p0_s7 <= {DATA_W{1'b0}};
            p0_mode <= 1'b0;
            p0_row <= 3'd0;
            p0_valid <= 1'b0;

            p1_acc <= {ACC_W{1'b0}};
            p1_row <= 3'd0;
            p1_valid <= 1'b0;

            coeff_out_r <= {OUT_W{1'b0}};
            index_out_r <= 3'd0;
            valid_out_r <= 1'b0;
        end else begin
            if (valid_in) begin
                sample_bank[index] <= sample_in;
                if (index == 3'd0)
                    block_mode <= mode;
            end

            if (valid_in && index == 3'd7) begin
                active <= 1'b1;
                row_ctr <= 3'd0;
            end else if (active) begin
                if (row_ctr == 3'd7)
                    active <= 1'b0;
                row_ctr <= row_ctr + 3'd1;
            end

            p0_s0 <= sample_bank[0];
            p0_s1 <= sample_bank[1];
            p0_s2 <= sample_bank[2];
            p0_s3 <= sample_bank[3];
            p0_s4 <= sample_bank[4];
            p0_s5 <= sample_bank[5];
            p0_s6 <= sample_bank[6];
            p0_s7 <= (valid_in && index == 3'd7) ? sample_in : sample_bank[7];
            p0_mode <= block_mode;
            p0_row <= row_ctr;
            p0_valid <= active;

            if (valid_in && index == 3'd7) begin
                p0_mode <= mode;
                p0_row <= 3'd0;
                p0_valid <= 1'b1;
            end

            p1_acc <= dot_acc;
            p1_row <= p0_row;
            p1_valid <= p0_valid;

            coeff_out_r <= rounded_out;
            index_out_r <= p1_row;
            valid_out_r <= p1_valid;
        end
    end

endmodule