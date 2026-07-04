`timescale 1ns/1ps

module fft64_streaming #(
    parameter DATA_W = 16,
    parameter POINTS = 64,
    parameter GROWTH = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] real_in,
    input [DATA_W-1:0] imag_in,
    input valid_in,
    input last_in,
    output [DATA_W+GROWTH-1:0] real_out,
    output [DATA_W+GROWTH-1:0] imag_out,
    output valid_out,
    output last_out,
    output done
);
    localparam OUT_W = DATA_W + GROWTH;
    localparam STAGES = 6;

    wire signed [OUT_W-1:0] in_real_ext;
    wire signed [OUT_W-1:0] in_imag_ext;

    fft_sign_extend #(
        .IN_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_extend (
        .real_in(real_in),
        .imag_in(imag_in),
        .real_out(in_real_ext),
        .imag_out(in_imag_ext)
    );

    reg signed [OUT_W-1:0] stage_real [0:STAGES];
    reg signed [OUT_W-1:0] stage_imag [0:STAGES];
    reg                    stage_valid [0:STAGES];
    reg                    stage_last [0:STAGES];

    wire signed [OUT_W-1:0] b0_real, b0_imag;
    wire signed [OUT_W-1:0] b1_real, b1_imag;
    wire signed [OUT_W-1:0] b2_real, b2_imag;
    wire signed [OUT_W-1:0] b3_real, b3_imag;
    wire signed [OUT_W-1:0] b4_real, b4_imag;
    wire signed [OUT_W-1:0] b5_real, b5_imag;

    wire signed [OUT_W-1:0] tw0_real, tw0_imag;
    wire signed [OUT_W-1:0] tw1_real, tw1_imag;
    wire signed [OUT_W-1:0] tw2_real, tw2_imag;
    wire signed [OUT_W-1:0] tw3_real, tw3_imag;
    wire signed [OUT_W-1:0] tw4_real, tw4_imag;
    wire signed [OUT_W-1:0] tw5_real, tw5_imag;

    reg [5:0] sample_count;
    wire [5:0] next_count;
    wire frame_last;

    fft_counter_next #(
        .POINTS(POINTS)
    ) u_counter_next (
        .count_in(sample_count),
        .valid_in(valid_in),
        .last_in(last_in),
        .count_out(next_count),
        .frame_last(frame_last)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(0)) u_tw0 (
        .sample_index(sample_count),
        .tw_real(tw0_real),
        .tw_imag(tw0_imag)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(1)) u_tw1 (
        .sample_index(sample_count),
        .tw_real(tw1_real),
        .tw_imag(tw1_imag)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(2)) u_tw2 (
        .sample_index(sample_count),
        .tw_real(tw2_real),
        .tw_imag(tw2_imag)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(3)) u_tw3 (
        .sample_index(sample_count),
        .tw_real(tw3_real),
        .tw_imag(tw3_imag)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(4)) u_tw4 (
        .sample_index(sample_count),
        .tw_real(tw4_real),
        .tw_imag(tw4_imag)
    );

    fft_twiddle_select #(.OUT_W(OUT_W), .STAGE_ID(5)) u_tw5 (
        .sample_index(sample_count),
        .tw_real(tw5_real),
        .tw_imag(tw5_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(0)) u_stage0 (
        .real_in(stage_real[0]),
        .imag_in(stage_imag[0]),
        .tw_real(tw0_real),
        .tw_imag(tw0_imag),
        .real_out(b0_real),
        .imag_out(b0_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(1)) u_stage1 (
        .real_in(stage_real[1]),
        .imag_in(stage_imag[1]),
        .tw_real(tw1_real),
        .tw_imag(tw1_imag),
        .real_out(b1_real),
        .imag_out(b1_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(2)) u_stage2 (
        .real_in(stage_real[2]),
        .imag_in(stage_imag[2]),
        .tw_real(tw2_real),
        .tw_imag(tw2_imag),
        .real_out(b2_real),
        .imag_out(b2_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(3)) u_stage3 (
        .real_in(stage_real[3]),
        .imag_in(stage_imag[3]),
        .tw_real(tw3_real),
        .tw_imag(tw3_imag),
        .real_out(b3_real),
        .imag_out(b3_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(4)) u_stage4 (
        .real_in(stage_real[4]),
        .imag_in(stage_imag[4]),
        .tw_real(tw4_real),
        .tw_imag(tw4_imag),
        .real_out(b4_real),
        .imag_out(b4_imag)
    );

    fft_stage_unit #(.W(OUT_W), .STAGE_ID(5)) u_stage5 (
        .real_in(stage_real[5]),
        .imag_in(stage_imag[5]),
        .tw_real(tw5_real),
        .tw_imag(tw5_imag),
        .real_out(b5_real),
        .imag_out(b5_imag)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            sample_count <= 6'd0;
            for (i = 0; i <= STAGES; i = i + 1) begin
                stage_real[i]  <= {OUT_W{1'b0}};
                stage_imag[i]  <= {OUT_W{1'b0}};
                stage_valid[i] <= 1'b0;
                stage_last[i]  <= 1'b0;
            end
        end else begin
            sample_count <= next_count;

            stage_real[0]  <= in_real_ext;
            stage_imag[0]  <= in_imag_ext;
            stage_valid[0] <= valid_in;
            stage_last[0]  <= frame_last;

            stage_real[1]  <= b0_real;
            stage_imag[1]  <= b0_imag;
            stage_valid[1] <= stage_valid[0];
            stage_last[1]  <= stage_last[0];

            stage_real[2]  <= b1_real;
            stage_imag[2]  <= b1_imag;
            stage_valid[2] <= stage_valid[1];
            stage_last[2]  <= stage_last[1];

            stage_real[3]  <= b2_real;
            stage_imag[3]  <= b2_imag;
            stage_valid[3] <= stage_valid[2];
            stage_last[3]  <= stage_last[2];

            stage_real[4]  <= b3_real;
            stage_imag[4]  <= b3_imag;
            stage_valid[4] <= stage_valid[3];
            stage_last[4]  <= stage_last[3];

            stage_real[5]  <= b4_real;
            stage_imag[5]  <= b4_imag;
            stage_valid[5] <= stage_valid[4];
            stage_last[5]  <= stage_last[4];

            stage_real[6]  <= b5_real;
            stage_imag[6]  <= b5_imag;
            stage_valid[6] <= stage_valid[5];
            stage_last[6]  <= stage_last[5];
        end
    end

    assign real_out  = stage_real[6];
    assign imag_out  = stage_imag[6];
    assign valid_out = stage_valid[6];
    assign last_out  = stage_last[6];
    assign done      = stage_valid[6] & stage_last[6];

endmodule