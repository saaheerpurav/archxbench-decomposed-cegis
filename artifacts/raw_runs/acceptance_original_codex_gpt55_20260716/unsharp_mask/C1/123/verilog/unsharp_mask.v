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
    output reg [PIXEL_W-1:0] pixel_out,
    output reg valid_out
);

    localparam SUM_W = PIXEL_W + 4;
    localparam DIFF_W = PIXEL_W + 2;
    localparam PROD_W = DIFF_W + GAIN_W;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] orig_delay [0:IMG_WIDTH];

    reg [PIXEL_W-1:0] w00, w01, w02;
    reg [PIXEL_W-1:0] w10, w11, w12;
    reg [PIXEL_W-1:0] w20, w21, w22;

    reg [PIXEL_W-1:0] orig_s0, orig_s1, orig_s2;
    reg [PIXEL_W-1:0] blur_s1;
    reg signed [DIFF_W-1:0] diff_s2;
    reg signed [PROD_W-1:0] scaled_s3;
    reg signed [PROD_W:0] recon_s4;

    reg valid_s0, valid_s1, valid_s2, valid_s3, valid_s4;

    reg [31:0] x;
    reg [31:0] y;

    integer i;

    wire [PIXEL_W-1:0] px_top = (y < 2) ? {PIXEL_W{1'b0}} : line1[x];
    wire [PIXEL_W-1:0] px_mid = (y < 1) ? {PIXEL_W{1'b0}} : line0[x];

    wire [SUM_W-1:0] gaussian_sum =
        w00 + (w01 << 1) + w02 +
        (w10 << 1) + (w11 << 2) + (w12 << 1) +
        w20 + (w21 << 1) + w22;

    wire [PIXEL_W-1:0] gaussian_blur = gaussian_sum[SUM_W-1:4];

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;

            w00 <= 0; w01 <= 0; w02 <= 0;
            w10 <= 0; w11 <= 0; w12 <= 0;
            w20 <= 0; w21 <= 0; w22 <= 0;

            orig_s0 <= 0;
            orig_s1 <= 0;
            orig_s2 <= 0;
            blur_s1 <= 0;
            diff_s2 <= 0;
            scaled_s3 <= 0;
            recon_s4 <= 0;

            valid_s0 <= 0;
            valid_s1 <= 0;
            valid_s2 <= 0;
            valid_s3 <= 0;
            valid_s4 <= 0;

            pixel_out <= 0;
            valid_out <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end

            for (i = 0; i <= IMG_WIDTH; i = i + 1) begin
                orig_delay[i] <= 0;
            end
        end else begin
            valid_s0 <= 0;

            if (valid_in) begin
                line0[x] <= pixel_in;
                line1[x] <= line0[x];

                orig_delay[0] <= pixel_in;
                for (i = 1; i <= IMG_WIDTH; i = i + 1) begin
                    orig_delay[i] <= orig_delay[i-1];
                end

                if (x == 0) begin
                    w00 <= 0;      w01 <= 0;      w02 <= px_top;
                    w10 <= 0;      w11 <= 0;      w12 <= px_mid;
                    w20 <= 0;      w21 <= 0;      w22 <= pixel_in;
                end else begin
                    w00 <= w01;    w01 <= w02;    w02 <= px_top;
                    w10 <= w11;    w11 <= w12;    w12 <= px_mid;
                    w20 <= w21;    w21 <= w22;    w22 <= pixel_in;
                end

                orig_s0 <= orig_delay[IMG_WIDTH];
                valid_s0 <= (y != 0) && (x != 0);

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

            blur_s1 <= gaussian_blur;
            orig_s1 <= orig_s0;
            valid_s1 <= valid_s0;

            diff_s2 <= $signed({1'b0, orig_s1}) - $signed({1'b0, blur_s1});
            orig_s2 <= orig_s1;
            valid_s2 <= valid_s1;

            scaled_s3 <= diff_s2 * $signed({1'b0, gain});
            valid_s3 <= valid_s2;

            recon_s4 <= $signed({1'b0, orig_s2}) + (scaled_s3 >>> GAIN_W);
            valid_s4 <= valid_s3;

            if (recon_s4 < 0)
                pixel_out <= 0;
            else if (recon_s4 > ((1 << PIXEL_W) - 1))
                pixel_out <= {PIXEL_W{1'b1}};
            else
                pixel_out <= recon_s4[PIXEL_W-1:0];

            valid_out <= valid_s4;
        end
    end

endmodule