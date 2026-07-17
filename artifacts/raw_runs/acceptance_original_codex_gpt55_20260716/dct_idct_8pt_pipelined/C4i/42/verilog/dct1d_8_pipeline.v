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

    reg signed [DATA_W-1:0] sample_mem [0:7];

    reg signed [DATA_W-1:0] x0;
    reg signed [DATA_W-1:0] x1;
    reg signed [DATA_W-1:0] x2;
    reg signed [DATA_W-1:0] x3;
    reg signed [DATA_W-1:0] x4;
    reg signed [DATA_W-1:0] x5;
    reg signed [DATA_W-1:0] x6;
    reg signed [DATA_W-1:0] x7;

    reg compute_valid_s1;
    reg compute_mode_s1;

    wire signed [DATA_W-1:0] current_sample = sample_in;
    wire end_of_block = valid_in && (index == 3'd7);

    integer mi;
    always @(*) begin
        x0 = sample_mem[0];
        x1 = sample_mem[1];
        x2 = sample_mem[2];
        x3 = sample_mem[3];
        x4 = sample_mem[4];
        x5 = sample_mem[5];
        x6 = sample_mem[6];
        x7 = sample_mem[7];

        if (valid_in) begin
            case (index)
                3'd0: x0 = current_sample;
                3'd1: x1 = current_sample;
                3'd2: x2 = current_sample;
                3'd3: x3 = current_sample;
                3'd4: x4 = current_sample;
                3'd5: x5 = current_sample;
                3'd6: x6 = current_sample;
                3'd7: x7 = current_sample;
                default: x0 = sample_mem[0];
            endcase
        end
    end

    wire signed [COEFF_W-1:0] c00, c01, c02, c03, c04, c05, c06, c07;
    wire signed [COEFF_W-1:0] c10, c11, c12, c13, c14, c15, c16, c17;
    wire signed [COEFF_W-1:0] c20, c21, c22, c23, c24, c25, c26, c27;
    wire signed [COEFF_W-1:0] c30, c31, c32, c33, c34, c35, c36, c37;
    wire signed [COEFF_W-1:0] c40, c41, c42, c43, c44, c45, c46, c47;
    wire signed [COEFF_W-1:0] c50, c51, c52, c53, c54, c55, c56, c57;
    wire signed [COEFF_W-1:0] c60, c61, c62, c63, c64, c65, c66, c67;
    wire signed [COEFF_W-1:0] c70, c71, c72, c73, c74, c75, c76, c77;

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r00(.mode(compute_mode_s1), .row(3'd0), .col(3'd0), .coeff(c00));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r01(.mode(compute_mode_s1), .row(3'd0), .col(3'd1), .coeff(c01));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r02(.mode(compute_mode_s1), .row(3'd0), .col(3'd2), .coeff(c02));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r03(.mode(compute_mode_s1), .row(3'd0), .col(3'd3), .coeff(c03));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r04(.mode(compute_mode_s1), .row(3'd0), .col(3'd4), .coeff(c04));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r05(.mode(compute_mode_s1), .row(3'd0), .col(3'd5), .coeff(c05));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r06(.mode(compute_mode_s1), .row(3'd0), .col(3'd6), .coeff(c06));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r07(.mode(compute_mode_s1), .row(3'd0), .col(3'd7), .coeff(c07));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r10(.mode(compute_mode_s1), .row(3'd1), .col(3'd0), .coeff(c10));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r11(.mode(compute_mode_s1), .row(3'd1), .col(3'd1), .coeff(c11));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r12(.mode(compute_mode_s1), .row(3'd1), .col(3'd2), .coeff(c12));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r13(.mode(compute_mode_s1), .row(3'd1), .col(3'd3), .coeff(c13));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r14(.mode(compute_mode_s1), .row(3'd1), .col(3'd4), .coeff(c14));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r15(.mode(compute_mode_s1), .row(3'd1), .col(3'd5), .coeff(c15));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r16(.mode(compute_mode_s1), .row(3'd1), .col(3'd6), .coeff(c16));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r17(.mode(compute_mode_s1), .row(3'd1), .col(3'd7), .coeff(c17));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r20(.mode(compute_mode_s1), .row(3'd2), .col(3'd0), .coeff(c20));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r21(.mode(compute_mode_s1), .row(3'd2), .col(3'd1), .coeff(c21));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r22(.mode(compute_mode_s1), .row(3'd2), .col(3'd2), .coeff(c22));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r23(.mode(compute_mode_s1), .row(3'd2), .col(3'd3), .coeff(c23));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r24(.mode(compute_mode_s1), .row(3'd2), .col(3'd4), .coeff(c24));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r25(.mode(compute_mode_s1), .row(3'd2), .col(3'd5), .coeff(c25));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r26(.mode(compute_mode_s1), .row(3'd2), .col(3'd6), .coeff(c26));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r27(.mode(compute_mode_s1), .row(3'd2), .col(3'd7), .coeff(c27));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r30(.mode(compute_mode_s1), .row(3'd3), .col(3'd0), .coeff(c30));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r31(.mode(compute_mode_s1), .row(3'd3), .col(3'd1), .coeff(c31));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r32(.mode(compute_mode_s1), .row(3'd3), .col(3'd2), .coeff(c32));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r33(.mode(compute_mode_s1), .row(3'd3), .col(3'd3), .coeff(c33));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r34(.mode(compute_mode_s1), .row(3'd3), .col(3'd4), .coeff(c34));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r35(.mode(compute_mode_s1), .row(3'd3), .col(3'd5), .coeff(c35));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r36(.mode(compute_mode_s1), .row(3'd3), .col(3'd6), .coeff(c36));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r37(.mode(compute_mode_s1), .row(3'd3), .col(3'd7), .coeff(c37));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r40(.mode(compute_mode_s1), .row(3'd4), .col(3'd0), .coeff(c40));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r41(.mode(compute_mode_s1), .row(3'd4), .col(3'd1), .coeff(c41));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r42(.mode(compute_mode_s1), .row(3'd4), .col(3'd2), .coeff(c42));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r43(.mode(compute_mode_s1), .row(3'd4), .col(3'd3), .coeff(c43));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r44(.mode(compute_mode_s1), .row(3'd4), .col(3'd4), .coeff(c44));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r45(.mode(compute_mode_s1), .row(3'd4), .col(3'd5), .coeff(c45));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r46(.mode(compute_mode_s1), .row(3'd4), .col(3'd6), .coeff(c46));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r47(.mode(compute_mode_s1), .row(3'd4), .col(3'd7), .coeff(c47));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r50(.mode(compute_mode_s1), .row(3'd5), .col(3'd0), .coeff(c50));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r51(.mode(compute_mode_s1), .row(3'd5), .col(3'd1), .coeff(c51));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r52(.mode(compute_mode_s1), .row(3'd5), .col(3'd2), .coeff(c52));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r53(.mode(compute_mode_s1), .row(3'd5), .col(3'd3), .coeff(c53));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r54(.mode(compute_mode_s1), .row(3'd5), .col(3'd4), .coeff(c54));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r55(.mode(compute_mode_s1), .row(3'd5), .col(3'd5), .coeff(c55));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r56(.mode(compute_mode_s1), .row(3'd5), .col(3'd6), .coeff(c56));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r57(.mode(compute_mode_s1), .row(3'd5), .col(3'd7), .coeff(c57));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r60(.mode(compute_mode_s1), .row(3'd6), .col(3'd0), .coeff(c60));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r61(.mode(compute_mode_s1), .row(3'd6), .col(3'd1), .coeff(c61));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r62(.mode(compute_mode_s1), .row(3'd6), .col(3'd2), .coeff(c62));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r63(.mode(compute_mode_s1), .row(3'd6), .col(3'd3), .coeff(c63));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r64(.mode(compute_mode_s1), .row(3'd6), .col(3'd4), .coeff(c64));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r65(.mode(compute_mode_s1), .row(3'd6), .col(3'd5), .coeff(c65));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r66(.mode(compute_mode_s1), .row(3'd6), .col(3'd6), .coeff(c66));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r67(.mode(compute_mode_s1), .row(3'd6), .col(3'd7), .coeff(c67));

    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r70(.mode(compute_mode_s1), .row(3'd7), .col(3'd0), .coeff(c70));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r71(.mode(compute_mode_s1), .row(3'd7), .col(3'd1), .coeff(c71));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r72(.mode(compute_mode_s1), .row(3'd7), .col(3'd2), .coeff(c72));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r73(.mode(compute_mode_s1), .row(3'd7), .col(3'd3), .coeff(c73));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r74(.mode(compute_mode_s1), .row(3'd7), .col(3'd4), .coeff(c74));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r75(.mode(compute_mode_s1), .row(3'd7), .col(3'd5), .coeff(c75));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r76(.mode(compute_mode_s1), .row(3'd7), .col(3'd6), .coeff(c76));
    dct1d_8_coeff_rom #(.COEFF_W(COEFF_W)) r77(.mode(compute_mode_s1), .row(3'd7), .col(3'd7), .coeff(c77));

    wire signed [ACC_W-1:0] acc0, acc1, acc2, acc3, acc4, acc5, acc6, acc7;

    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m0(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c00), .c1(c01), .c2(c02), .c3(c03), .c4(c04), .c5(c05), .c6(c06), .c7(c07),
        .acc(acc0)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m1(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c10), .c1(c11), .c2(c12), .c3(c13), .c4(c14), .c5(c15), .c6(c16), .c7(c17),
        .acc(acc1)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m2(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c20), .c1(c21), .c2(c22), .c3(c23), .c4(c24), .c5(c25), .c6(c26), .c7(c27),
        .acc(acc2)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m3(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c30), .c1(c31), .c2(c32), .c3(c33), .c4(c34), .c5(c35), .c6(c36), .c7(c37),
        .acc(acc3)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m4(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c40), .c1(c41), .c2(c42), .c3(c43), .c4(c44), .c5(c45), .c6(c46), .c7(c47),
        .acc(acc4)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m5(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c50), .c1(c51), .c2(c52), .c3(c53), .c4(c54), .c5(c55), .c6(c56), .c7(c57),
        .acc(acc5)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m6(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c60), .c1(c61), .c2(c62), .c3(c63), .c4(c64), .c5(c65), .c6(c66), .c7(c67),
        .acc(acc6)
    );
    dct1d_8_mac8 #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)) m7(
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6), .x7(x7),
        .c0(c70), .c1(c71), .c2(c72), .c3(c73), .c4(c74), .c5(c75), .c6(c76), .c7(c77),
        .acc(acc7)
    );

    wire signed [OUT_W-1:0] y0, y1, y2, y3, y4, y5, y6, y7;

    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s0(.acc(acc0), .out(y0));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s1(.acc(acc1), .out(y1));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s2(.acc(acc2), .out(y2));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s3(.acc(acc3), .out(y3));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s4(.acc(acc4), .out(y4));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s5(.acc(acc5), .out(y5));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s6(.acc(acc6), .out(y6));
    dct1d_8_round_sat #(.ACC_W(ACC_W), .OUT_W(OUT_W), .SHIFT(14)) s7(.acc(acc7), .out(y7));

    reg signed [OUT_W-1:0] out_mem [0:7];
    reg [3:0] emit_count;
    reg emitting;
    reg [OUT_W-1:0] coeff_out_r;
    reg valid_out_r;
    reg [2:0] index_out_r;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    always @(posedge clk) begin
        if (rst) begin
            for (mi = 0; mi < 8; mi = mi + 1) begin
                sample_mem[mi] <= {DATA_W{1'b0}};
                out_mem[mi] <= {OUT_W{1'b0}};
            end
            compute_valid_s1 <= 1'b0;
            compute_mode_s1 <= 1'b0;
            emitting <= 1'b0;
            emit_count <= 4'd0;
            coeff_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            index_out_r <= 3'd0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in) begin
                sample_mem[index] <= current_sample;
            end

            compute_valid_s1 <= end_of_block;
            if (end_of_block) begin
                compute_mode_s1 <= mode;
            end

            if (compute_valid_s1) begin
                out_mem[0] <= y0;
                out_mem[1] <= y1;
                out_mem[2] <= y2;
                out_mem[3] <= y3;
                out_mem[4] <= y4;
                out_mem[5] <= y5;
                out_mem[6] <= y6;
                out_mem[7] <= y7;
                emitting <= 1'b1;
                emit_count <= 4'd0;
            end else if (emitting) begin
                valid_out_r <= 1'b1;
                index_out_r <= emit_count[2:0];
                coeff_out_r <= out_mem[emit_count[2:0]];

                if (emit_count == 4'd7) begin
                    emitting <= 1'b0;
                    emit_count <= 4'd0;
                end else begin
                    emit_count <= emit_count + 4'd1;
                end
            end
        end
    end

endmodule