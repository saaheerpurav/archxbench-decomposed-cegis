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
    localparam PAIR_CNT   = (TAP_CNT-1)/2;
    localparam COEFF_W    = 16;
    localparam PAIR_W     = DATA_W + 1;
    localparam PROD_W     = PAIR_W + COEFF_W;
    localparam ACC_W      = 64;

    reg signed [DATA_W-1:0] samples [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] new_sample;
    wire [DATA_W*TAP_CNT-1:0] sample_bus;
    wire [DATA_W*TAP_CNT-1:0] next_sample_bus;
    wire [COEFF_W*(PAIR_CNT+1)-1:0] coeff_bus;
    wire signed [ACC_W-1:0] acc_full;
    wire signed [OUT_W-1:0] scaled_out;

    integer i;

    assign new_sample = $signed(data_in);

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : PACK_SAMPLES
            assign sample_bus[(gi+1)*DATA_W-1 -: DATA_W] = samples[gi];
            if (gi == 0) begin : PACK_NEXT_HEAD
                assign next_sample_bus[(gi+1)*DATA_W-1 -: DATA_W] = new_sample;
            end else begin : PACK_NEXT_TAIL
                assign next_sample_bus[(gi+1)*DATA_W-1 -: DATA_W] = samples[gi-1];
            end
        end

        for (gi = 0; gi <= PAIR_CNT; gi = gi + 1) begin : COEFFS
            lowpass_fir_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) coeff_rom_i (
                .addr(gi[6:0]),
                .coeff(coeff_bus[(gi+1)*COEFF_W-1 -: COEFF_W])
            );
        end
    endgenerate

    lowpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) mac_i (
        .sample_bus(next_sample_bus),
        .coeff_bus(coeff_bus),
        .acc_out(acc_full)
    );

    lowpass_fir_output_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) scale_i (
        .acc_in(acc_full),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                samples[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= scaled_out;
                samples[0] <= new_sample;
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    samples[i] <= samples[i-1];
                end
            end
        end
    end
endmodule