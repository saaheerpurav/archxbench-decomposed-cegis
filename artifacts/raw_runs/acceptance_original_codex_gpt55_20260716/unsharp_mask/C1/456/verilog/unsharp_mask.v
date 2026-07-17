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

    localparam X_W = clog2(IMG_WIDTH);
    localparam Y_W = clog2(IMG_HEIGHT);
    localparam ACC_W = PIXEL_W + 8;
    localparam SIGNED_W = ACC_W + GAIN_W + 4;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] w00, w01, w02;
    reg [PIXEL_W-1:0] w10, w11, w12;
    reg [PIXEL_W-1:0] w20, w21, w22;

    reg [X_W-1:0] x;
    reg [Y_W-1:0] y;

    reg valid_win;
    reg valid_conv;
    reg valid_point;

    reg [PIXEL_W-1:0] orig_conv;
    reg [PIXEL_W-1:0] orig_point;
    reg [PIXEL_W-1:0] blur_point;

    reg [PIXEL_W-1:0] pixel_out_r;
    reg valid_out_r;

    integer i;

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 1;
            while (v > 1) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    function [PIXEL_W-1:0] sat_pixel;
        input signed [SIGNED_W-1:0] value;
        begin
            if (value < 0)
                sat_pixel = {PIXEL_W{1'b0}};
            else if (value > ((1 << PIXEL_W) - 1))
                sat_pixel = {PIXEL_W{1'b1}};
            else
                sat_pixel = value[PIXEL_W-1:0];
        end
    endfunction

    wire [PIXEL_W-1:0] row0_pix = (y >= 2) ? line1[x] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] row1_pix = (y >= 1) ? line0[x] : {PIXEL_W{1'b0}};
    wire [PIXEL_W-1:0] row2_pix = pixel_in;

    wire [ACC_W-1:0] conv_sum =
        (w00 * K00) + (w01 * K01) + (w02 * K02) +
        (w10 * K10) + (w11 * K11) + (w12 * K12) +
        (w20 * K20) + (w21 * K21) + (w22 * K22);

    wire [PIXEL_W-1:0] blur_calc = conv_sum >> K_SHIFT;

    wire signed [SIGNED_W-1:0] orig_s =
        {{(SIGNED_W-PIXEL_W){1'b0}}, orig_point};

    wire signed [SIGNED_W-1:0] blur_s =
        {{(SIGNED_W-PIXEL_W){1'b0}}, blur_point};

    wire signed [SIGNED_W-1:0] high_s = orig_s - blur_s;

    wire signed [SIGNED_W-1:0] scaled_s =
        (high_s * $signed({1'b0, gain})) >>> (GAIN_W-1);

    wire signed [SIGNED_W-1:0] sharp_s = orig_s + scaled_s;

    always @(posedge clk) begin
        if (rst) begin
            x <= {X_W{1'b0}};
            y <= {Y_W{1'b0}};

            w00 <= {PIXEL_W{1'b0}};
            w01 <= {PIXEL_W{1'b0}};
            w02 <= {PIXEL_W{1'b0}};
            w10 <= {PIXEL_W{1'b0}};
            w11 <= {PIXEL_W{1'b0}};
            w12 <= {PIXEL_W{1'b0}};
            w20 <= {PIXEL_W{1'b0}};
            w21 <= {PIXEL_W{1'b0}};
            w22 <= {PIXEL_W{1'b0}};

            valid_win <= 1'b0;
            valid_conv <= 1'b0;
            valid_point <= 1'b0;
            valid_out_r <= 1'b0;

            orig_conv <= {PIXEL_W{1'b0}};
            orig_point <= {PIXEL_W{1'b0}};
            blur_point <= {PIXEL_W{1'b0}};
            pixel_out_r <= {PIXEL_W{1'b0}};

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= {PIXEL_W{1'b0}};
                line1[i] <= {PIXEL_W{1'b0}};
            end
        end else begin
            valid_win <= 1'b0;

            if (valid_in) begin
                line0[x] <= pixel_in;
                line1[x] <= line0[x];

                if (x == 0) begin
                    w00 <= {PIXEL_W{1'b0}};
                    w01 <= {PIXEL_W{1'b0}};
                    w02 <= row0_pix;

                    w10 <= {PIXEL_W{1'b0}};
                    w11 <= {PIXEL_W{1'b0}};
                    w12 <= row1_pix;

                    w20 <= {PIXEL_W{1'b0}};
                    w21 <= {PIXEL_W{1'b0}};
                    w22 <= row2_pix;
                end else begin
                    w00 <= w01;
                    w01 <= w02;
                    w02 <= row0_pix;

                    w10 <= w11;
                    w11 <= w12;
                    w12 <= row1_pix;

                    w20 <= w21;
                    w21 <= w22;
                    w22 <= row2_pix;
                end

                valid_win <= 1'b1;

                if (x == IMG_WIDTH-1) begin
                    x <= {X_W{1'b0}};
                    if (y == IMG_HEIGHT-1)
                        y <= {Y_W{1'b0}};
                    else
                        y <= y + 1'b1;
                end else begin
                    x <= x + 1'b1;
                end
            end

            valid_conv <= valid_win;
            orig_conv <= w11;

            valid_point <= valid_conv;
            orig_point <= orig_conv;
            blur_point <= blur_calc;

            valid_out_r <= valid_point;
            if (valid_point)
                pixel_out_r <= sat_pixel(sharp_s);
        end
    end

endmodule