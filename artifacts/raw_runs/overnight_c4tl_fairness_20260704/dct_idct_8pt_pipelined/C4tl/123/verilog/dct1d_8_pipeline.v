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

    reg signed [DATA_W-1:0] sample_mem0;
    reg signed [DATA_W-1:0] sample_mem1;
    reg signed [DATA_W-1:0] sample_mem2;
    reg signed [DATA_W-1:0] sample_mem3;
    reg signed [DATA_W-1:0] sample_mem4;
    reg signed [DATA_W-1:0] sample_mem5;
    reg signed [DATA_W-1:0] sample_mem6;
    reg signed [DATA_W-1:0] sample_mem7;

    reg block_ready;
    reg block_mode;
    reg out_active;
    reg [2:0] out_count;

    wire signed [COEFF_W-1:0] c0;
    wire signed [COEFF_W-1:0] c1;
    wire signed [COEFF_W-1:0] c2;
    wire signed [COEFF_W-1:0] c3;
    wire signed [COEFF_W-1:0] c4;
    wire signed [COEFF_W-1:0] c5;
    wire signed [COEFF_W-1:0] c6;
    wire signed [COEFF_W-1:0] c7;

    wire signed [DATA_W-1:0] cur_s0 = (valid_in && index == 3'd0) ? sample_in : sample_mem0;
    wire signed [DATA_W-1:0] cur_s1 = (valid_in && index == 3'd1) ? sample_in : sample_mem1;
    wire signed [DATA_W-1:0] cur_s2 = (valid_in && index == 3'd2) ? sample_in : sample_mem2;
    wire signed [DATA_W-1:0] cur_s3 = (valid_in && index == 3'd3) ? sample_in : sample_mem3;
    wire signed [DATA_W-1:0] cur_s4 = (valid_in && index == 3'd4) ? sample_in : sample_mem4;
    wire signed [DATA_W-1:0] cur_s5 = (valid_in && index == 3'd5) ? sample_in : sample_mem5;
    wire signed [DATA_W-1:0] cur_s6 = (valid_in && index == 3'd6) ? sample_in : sample_mem6;
    wire signed [DATA_W-1:0] cur_s7 = (valid_in && index == 3'd7) ? sample_in : sample_mem7;

    wire [2:0] calc_index = out_count;
    wire calc_mode = out_active ? block_mode : mode;

    wire signed [DATA_W+COEFF_W+4:0] mac_sum;
    wire signed [OUT_W-1:0] scaled_result;

    dct1d_8_coeff_rom #(
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .mode(calc_mode),
        .out_index(calc_index),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    dct1d_8_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W)
    ) u_mac (
        .s0(cur_s0),
        .s1(cur_s1),
        .s2(cur_s2),
        .s3(cur_s3),
        .s4(cur_s4),
        .s5(cur_s5),
        .s6(cur_s6),
        .s7(cur_s7),
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

    dct1d_8_round_sat #(
        .IN_W(DATA_W+COEFF_W+5),
        .OUT_W(OUT_W),
        .SHIFT(14)
    ) u_round_sat (
        .in_value(mac_sum),
        .out_value(scaled_result)
    );

    assign coeff_out = scaled_result;
    assign valid_out = out_active;
    assign index_out = out_count;

    always @(posedge clk) begin
        if (rst) begin
            sample_mem0 <= 0;
            sample_mem1 <= 0;
            sample_mem2 <= 0;
            sample_mem3 <= 0;
            sample_mem4 <= 0;
            sample_mem5 <= 0;
            sample_mem6 <= 0;
            sample_mem7 <= 0;
            block_ready <= 1'b0;
            block_mode <= 1'b0;
            out_active <= 1'b0;
            out_count <= 3'd0;
        end else begin
            if (valid_in) begin
                case (index)
                    3'd0: sample_mem0 <= sample_in;
                    3'd1: sample_mem1 <= sample_in;
                    3'd2: sample_mem2 <= sample_in;
                    3'd3: sample_mem3 <= sample_in;
                    3'd4: sample_mem4 <= sample_in;
                    3'd5: sample_mem5 <= sample_in;
                    3'd6: sample_mem6 <= sample_in;
                    3'd7: sample_mem7 <= sample_in;
                    default: sample_mem0 <= sample_mem0;
                endcase

                if (index == 3'd7) begin
                    block_ready <= 1'b1;
                    block_mode <= mode;
                end
            end

            if (out_active) begin
                if (out_count == 3'd7) begin
                    out_active <= 1'b0;
                    out_count <= 3'd0;
                    block_ready <= 1'b0;
                end else begin
                    out_count <= out_count + 3'd1;
                end
            end else if (block_ready && !valid_in) begin
                out_active <= 1'b1;
                out_count <= 3'd0;
            end
        end
    end

endmodule