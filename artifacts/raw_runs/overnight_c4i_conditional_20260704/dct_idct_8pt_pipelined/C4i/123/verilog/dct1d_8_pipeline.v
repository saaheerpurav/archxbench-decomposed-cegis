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
    localparam FRAC_BITS = 14;

    reg signed [DATA_W-1:0] x0, x1, x2, x3, x4, x5, x6, x7;
    reg block_ready;
    reg out_active;
    reg [2:0] out_idx;
    reg out_mode;

    wire signed [DATA_W-1:0] s0, s1, s2, s3, s4, s5, s6, s7;
    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
    wire signed [ACC_W-1:0] mac_sum;
    wire signed [OUT_W-1:0] rounded_result;

    dct_input_vector #(
        .DATA_W(DATA_W)
    ) u_input_vector (
        .x0(x0), .x1(x1), .x2(x2), .x3(x3),
        .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .s0(s0), .s1(s1), .s2(s2), .s3(s3),
        .s4(s4), .s5(s5), .s6(s6), .s7(s7)
    );

    dct_coeff_row_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_row_rom (
        .mode(out_mode),
        .row(out_idx),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3),
        .c4(c4), .c5(c5), .c6(c6), .c7(c7)
    );

    dct_mac8 #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac8 (
        .s0(s0), .s1(s1), .s2(s2), .s3(s3),
        .s4(s4), .s5(s5), .s6(s6), .s7(s7),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3),
        .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .sum(mac_sum)
    );

    dct_round_saturate #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .FRAC_BITS(FRAC_BITS)
    ) u_round_saturate (
        .in_value(mac_sum),
        .out_value(rounded_result)
    );

    assign coeff_out = rounded_result;
    assign valid_out = out_active;
    assign index_out = out_idx;

    always @(posedge clk) begin
        if (rst) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0;
            x4 <= 0; x5 <= 0; x6 <= 0; x7 <= 0;
            block_ready <= 1'b0;
            out_active <= 1'b0;
            out_idx <= 3'd0;
            out_mode <= 1'b0;
        end else begin
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
                    default: begin end
                endcase

                if (index == 3'd7) begin
                    block_ready <= 1'b1;
                    out_mode <= mode;
                end
            end

            if (out_active) begin
                if (out_idx == 3'd7) begin
                    out_active <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end else if (block_ready) begin
                out_active <= 1'b1;
                out_idx <= 3'd0;
                block_ready <= 1'b0;
            end
        end
    end

endmodule