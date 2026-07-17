`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output reg                  valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W      = DATA_W + GAIN_W;
    localparam COEFF_W    = 16;
    localparam ACC_W      = 64;
    localparam PAIR_CNT   = (TAP_CNT - 1) / 2;
    localparam CENTER_IDX = PAIR_CNT;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] sample_now;
    wire [DATA_W*TAP_CNT-1:0] sample_bus;
    wire [COEFF_W*TAP_CNT-1:0] coeff_bus;
    wire signed [(DATA_W+1)*PAIR_CNT-1:0] pair_sum_bus;
    wire signed [ACC_W-1:0] mac_accum;
    wire signed [OUT_W-1:0] norm_out;

    integer i;

    assign sample_now = $signed(data_in);

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : g_sample_bus
            if (gi == 0) begin : g_current_sample
                assign sample_bus[gi*DATA_W +: DATA_W] = sample_now;
            end else begin : g_delayed_sample
                assign sample_bus[gi*DATA_W +: DATA_W] = delay_line[gi-1];
            end
        end

        for (gi = 0; gi < PAIR_CNT; gi = gi + 1) begin : g_pair_add
            wire signed [DATA_W-1:0] left_sample;
            wire signed [DATA_W-1:0] right_sample;

            assign left_sample  = sample_bus[gi*DATA_W +: DATA_W];
            assign right_sample = sample_bus[(TAP_CNT-1-gi)*DATA_W +: DATA_W];

            fir_tap_pair_adder #(
                .DATA_W(DATA_W)
            ) u_pair_adder (
                .sample_a(left_sample),
                .sample_b(right_sample),
                .pair_sum(pair_sum_bus[gi*(DATA_W+1) +: (DATA_W+1)])
            );
        end
    endgenerate

    fir_coeff_rom_101 #(
        .COEFF_W(COEFF_W),
        .TAP_CNT(TAP_CNT)
    ) u_coeff_rom (
        .coeff_bus(coeff_bus)
    );

    fir_symmetric_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .pair_sum_bus(pair_sum_bus),
        .center_sample(sample_bus[CENTER_IDX*DATA_W +: DATA_W]),
        .coeff_bus(coeff_bus),
        .accum(mac_accum)
    );

    fir_q15_normalizer #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_normalizer (
        .accum(mac_accum),
        .data_out(norm_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                delay_line[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= norm_out;

                delay_line[0] <= sample_now;
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    delay_line[i] <= delay_line[i-1];
                end
            end
        end
    end
endmodule