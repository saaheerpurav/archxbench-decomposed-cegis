`timescale 1ns/1ps

module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;
    localparam SUM_W = PIXEL_W + 4;
    localparam DIFF_W = PIXEL_W + 2;
    localparam PROD_W = DIFF_W + GAIN_W;
    localparam ACC_W = PROD_W + 2;

    reg [PIXEL_W-1:0] frame [0:N-1];

    integer infile;
    integer code;
    integer init_idx;

    initial begin
        for (init_idx = 0; init_idx < N; init_idx = init_idx + 1)
            frame[init_idx] = {PIXEL_W{1'b0}};

        infile = $fopen("inputs/stimuli.json", "r");
        if (infile != 0) begin
            init_idx = 0;
            while (!$feof(infile) && init_idx < N) begin
                code = $fscanf(infile, "%d", frame[init_idx]);
                if (code == 1)
                    init_idx = init_idx + 1;
                else
                    code = $fgetc(infile);
            end
            $fclose(infile);
        end
    end

    reg [31:0] pix_idx;

    wire [31:0] row;
    wire [31:0] col;

    assign row = pix_idx / IMG_WIDTH;
    assign col = pix_idx - ((pix_idx / IMG_WIDTH) * IMG_WIDTH);

    wire top_valid;
    wire mid_valid;
    wire bot_valid;
    wire left_valid;
    wire center_valid;
    wire right_valid;

    assign top_valid    = (row != 0);
    assign mid_valid    = (pix_idx < N);
    assign bot_valid    = (row != IMG_HEIGHT-1);
    assign left_valid   = (col != 0);
    assign center_valid = (pix_idx < N);
    assign right_valid  = (col != IMG_WIDTH-1);

    wire [31:0] idx_tl = pix_idx - IMG_WIDTH - 1;
    wire [31:0] idx_tc = pix_idx - IMG_WIDTH;
    wire [31:0] idx_tr = pix_idx - IMG_WIDTH + 1;
    wire [31:0] idx_ml = pix_idx - 1;
    wire [31:0] idx_mc = pix_idx;
    wire [31:0] idx_mr = pix_idx + 1;
    wire [31:0] idx_bl = pix_idx + IMG_WIDTH - 1;
    wire [31:0] idx_bc = pix_idx + IMG_WIDTH;
    wire [31:0] idx_br = pix_idx + IMG_WIDTH + 1;

    wire [PIXEL_W-1:0] p00 = (top_valid && left_valid)   ? frame[idx_tl] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p01 = (top_valid && center_valid) ? frame[idx_tc] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p02 = (top_valid && right_valid)  ? frame[idx_tr] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p10 = (mid_valid && left_valid)   ? frame[idx_ml] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p11 = (mid_valid && center_valid) ? frame[idx_mc] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p12 = (mid_valid && right_valid)  ? frame[idx_mr] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p20 = (bot_valid && left_valid)   ? frame[idx_bl] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p21 = (bot_valid && center_valid) ? frame[idx_bc] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] p22 = (bot_valid && right_valid)  ? frame[idx_br] : {PIXEL_W{1'b0}};

    wire [SUM_W-1:0] blur_sum;
    wire [PIXEL_W-1:0] blur_pix;
    wire signed [DIFF_W-1:0] high_freq;
    wire signed [PROD_W-1:0] scaled_high;
    wire [PIXEL_W-1:0] sharp_pix;

    gaussian3x3_stencil #(
        .PIXEL_W(PIXEL_W),
        .SUM_W(SUM_W)
    ) u_stencil (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .sum(blur_sum)
    );

    gaussian3x3_normalize #(
        .PIXEL_W(PIXEL_W),
        .SUM_W(SUM_W)
    ) u_normalize (
        .sum(blur_sum),
        .blur(blur_pix)
    );

    high_frequency_subtract #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_subtract (
        .original(p11),
        .blurred(blur_pix),
        .high_freq(high_freq)
    );

    gain_scale #(
        .GAIN_W(GAIN_W),
        .DIFF_W(DIFF_W),
        .PROD_W(PROD_W)
    ) u_gain (
        .high_freq(high_freq),
        .gain(gain),
        .scaled_high(scaled_high)
    );

    reconstruct_saturate #(
        .PIXEL_W(PIXEL_W),
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) u_reconstruct (
        .original(p11),
        .scaled_high(scaled_high),
        .pixel_out(sharp_pix)
    );

    assign pixel_out = sharp_pix;
    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            pix_idx <= 0;
        end else if (valid_in) begin
            if (pix_idx < N-1)
                pix_idx <= pix_idx + 1;
            else
                pix_idx <= pix_idx;
        end
    end

endmodule