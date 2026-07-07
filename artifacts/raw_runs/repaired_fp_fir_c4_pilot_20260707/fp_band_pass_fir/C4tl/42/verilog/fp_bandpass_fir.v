`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    localparam ACC_W      = 64;
    localparam SAMPLE_Q   = 20;
    localparam COEFF_Q    = 24;
    localparam TOTAL_LAT  = TAP_CNT;

    reg [31:0] samples [0:TAP_CNT-1];
    reg [TOTAL_LAT:0] valid_pipe;
    reg [31:0] data_out_r;

    wire signed [31:0] sample_q [0:TAP_CNT-1];
    wire signed [31:0] coeff_q  [0:TAP_CNT-1];

    wire signed [ACC_W-1:0] fir_accum;
    wire [31:0] fir_float;

    integer i;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : GEN_TAPS
            fp32_to_q #(
                .Q(SAMPLE_Q)
            ) u_sample_to_q (
                .fp_in(samples[g]),
                .q_out(sample_q[g])
            );

            fp_bandpass_coeff #(
                .INDEX(g),
                .COEFF_Q(COEFF_Q)
            ) u_coeff (
                .coeff_q(coeff_q[g])
            );
        end
    endgenerate

    fp_fir_mac #(
        .TAP_CNT(TAP_CNT),
        .SAMPLE_Q(SAMPLE_Q),
        .COEFF_Q(COEFF_Q),
        .ACC_W(ACC_W)
    ) u_mac (
        .s0(sample_q[0]),   .c0(coeff_q[0]),
        .s1(sample_q[1]),   .c1(coeff_q[1]),
        .s2(sample_q[2]),   .c2(coeff_q[2]),
        .s3(sample_q[3]),   .c3(coeff_q[3]),
        .s4(sample_q[4]),   .c4(coeff_q[4]),
        .s5(sample_q[5]),   .c5(coeff_q[5]),
        .s6(sample_q[6]),   .c6(coeff_q[6]),
        .s7(sample_q[7]),   .c7(coeff_q[7]),
        .s8(sample_q[8]),   .c8(coeff_q[8]),
        .s9(sample_q[9]),   .c9(coeff_q[9]),
        .s10(sample_q[10]), .c10(coeff_q[10]),
        .s11(sample_q[11]), .c11(coeff_q[11]),
        .s12(sample_q[12]), .c12(coeff_q[12]),
        .s13(sample_q[13]), .c13(coeff_q[13]),
        .s14(sample_q[14]), .c14(coeff_q[14]),
        .s15(sample_q[15]), .c15(coeff_q[15]),
        .s16(sample_q[16]), .c16(coeff_q[16]),
        .s17(sample_q[17]), .c17(coeff_q[17]),
        .s18(sample_q[18]), .c18(coeff_q[18]),
        .s19(sample_q[19]), .c19(coeff_q[19]),
        .s20(sample_q[20]), .c20(coeff_q[20]),
        .s21(sample_q[21]), .c21(coeff_q[21]),
        .s22(sample_q[22]), .c22(coeff_q[22]),
        .s23(sample_q[23]), .c23(coeff_q[23]),
        .s24(sample_q[24]), .c24(coeff_q[24]),
        .s25(sample_q[25]), .c25(coeff_q[25]),
        .s26(sample_q[26]), .c26(coeff_q[26]),
        .s27(sample_q[27]), .c27(coeff_q[27]),
        .s28(sample_q[28]), .c28(coeff_q[28]),
        .s29(sample_q[29]), .c29(coeff_q[29]),
        .s30(sample_q[30]), .c30(coeff_q[30]),
        .accum(fir_accum)
    );

    q_to_fp32 #(
        .IN_Q(SAMPLE_Q + COEFF_Q),
        .IN_W(ACC_W)
    ) u_q_to_fp (
        .q_in(fir_accum),
        .fp_out(fir_float)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                samples[i] <= 32'h00000000;
            valid_pipe <= {TOTAL_LAT+1{1'b0}};
            data_out_r <= 32'h00000000;
        end else begin
            if (valid_in) begin
                samples[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    samples[i] <= samples[i-1];
            end

            valid_pipe <= {valid_pipe[TOTAL_LAT-1:0], valid_in};
            data_out_r <= fir_float;
        end
    end

    assign valid_out = valid_pipe[TOTAL_LAT];
    assign data_out  = data_out_r;

endmodule