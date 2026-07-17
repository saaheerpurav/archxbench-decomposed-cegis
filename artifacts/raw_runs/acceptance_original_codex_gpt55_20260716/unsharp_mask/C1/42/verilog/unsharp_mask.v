module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8,
    parameter K00 = 1,
    parameter K01 = 2,
    parameter K02 = 1,
    parameter K10 = 2,
    parameter K11 = 4,
    parameter K12 = 2,
    parameter K20 = 1,
    parameter K21 = 2,
    parameter K22 = 1,
    parameter K_SHIFT = 4
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    localparam ACC_W = PIXEL_W + 8;
    localparam SIGNED_W = PIXEL_W + GAIN_W + 4;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] t0_0, t0_1, t0_2;
    reg [PIXEL_W-1:0] t1_0, t1_1, t1_2;
    reg [PIXEL_W-1:0] t2_0, t2_1, t2_2;

    reg [31:0] x;
    reg [31:0] y;
    integer i;

    reg [PIXEL_W-1:0] orig_s0;
    reg [PIXEL_W-1:0] orig_s1;
    reg [PIXEL_W-1:0] blur_s1;
    reg valid_s0;
    reg valid_s1;

    reg [PIXEL_W-1:0] pixel_out_r;
    reg valid_out_r;

    wire [ACC_W-1:0] conv_sum;
    wire [PIXEL_W-1:0] blur_now;

    assign conv_sum =
        (t0_0 * K00) + (t0_1 * K01) + (t0_2 * K02) +
        (t1_0 * K10) + (t1_1 * K11) + (t1_2 * K12) +
        (t2_0 * K20) + (t2_1 * K21) + (t2_2 * K22);

    assign blur_now = conv_sum[ACC_W-1:K_SHIFT] > {PIXEL_W{1'b1}} ?
                      {PIXEL_W{1'b1}} :
                      conv_sum[K_SHIFT +: PIXEL_W];

    function [PIXEL_W-1:0] sat_pixel;
        input signed [SIGNED_W-1:0] v;
        begin
            if (v < 0)
                sat_pixel = {PIXEL_W{1'b0}};
            else if (v > ((1 << PIXEL_W) - 1))
                sat_pixel = {PIXEL_W{1'b1}};
            else
                sat_pixel = v[PIXEL_W-1:0];
        end
    endfunction

    reg signed [SIGNED_W-1:0] diff_s;
    reg signed [SIGNED_W-1:0] scaled_s;
    reg signed [SIGNED_W-1:0] sharp_s;

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;

            t0_0 <= 0; t0_1 <= 0; t0_2 <= 0;
            t1_0 <= 0; t1_1 <= 0; t1_2 <= 0;
            t2_0 <= 0; t2_1 <= 0; t2_2 <= 0;

            orig_s0 <= 0;
            orig_s1 <= 0;
            blur_s1 <= 0;
            valid_s0 <= 0;
            valid_s1 <= 0;
            pixel_out_r <= 0;
            valid_out_r <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else begin
            valid_s0 <= valid_in;
            valid_s1 <= valid_s0;
            valid_out_r <= valid_s1;

            if (valid_in) begin
                t0_0 <= (x < 2 || y < 2) ? 0 : t0_1;
                t0_1 <= (x < 1 || y < 2) ? 0 : t0_2;
                t0_2 <= (y < 2) ? 0 : line0[x];

                t1_0 <= (x < 2 || y < 1) ? 0 : t1_1;
                t1_1 <= (x < 1 || y < 1) ? 0 : t1_2;
                t1_2 <= (y < 1) ? 0 : line1[x];

                t2_0 <= (x < 2) ? 0 : t2_1;
                t2_1 <= (x < 1) ? 0 : t2_2;
                t2_2 <= pixel_in;

                line0[x] <= line1[x];
                line1[x] <= pixel_in;

                orig_s0 <= pixel_in;

                if (x == IMG_WIDTH - 1) begin
                    x <= 0;
                    if (y == IMG_HEIGHT - 1)
                        y <= 0;
                    else
                        y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end

            orig_s1 <= orig_s0;
            blur_s1 <= blur_now;

            diff_s = $signed({1'b0, orig_s1}) - $signed({1'b0, blur_s1});
            scaled_s = (diff_s * $signed({1'b0, gain})) >>> (GAIN_W - 1);
            sharp_s = $signed({1'b0, orig_s1}) + scaled_s;
            pixel_out_r <= sat_pixel(sharp_s);
        end
    end

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;

endmodule