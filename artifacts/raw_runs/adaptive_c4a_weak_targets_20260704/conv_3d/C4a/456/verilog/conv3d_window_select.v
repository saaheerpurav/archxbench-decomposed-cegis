`timescale 1ns/1ps

module conv3d_window_select #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8
) (
    input  [D*H*W*DATA_W-1:0] samples,
    output [K1*K2*K3*DATA_W-1:0] window
);

    genvar kd, kh, kw;

    generate
        for (kd = 0; kd < K1; kd = kd + 1) begin : gen_depth
            for (kh = 0; kh < K2; kh = kh + 1) begin : gen_height
                for (kw = 0; kw < K3; kw = kw + 1) begin : gen_width
                    localparam integer WINDOW_INDEX =
                        ((kd * K2 * K3) + (kh * K3) + kw) * DATA_W;

                    localparam integer SAMPLE_DELAY =
                        ((K1 - 1 - kd) * H * W) +
                        ((K2 - 1 - kh) * W) +
                        (K3 - 1 - kw);

                    assign window[WINDOW_INDEX +: DATA_W] =
                        samples[SAMPLE_DELAY * DATA_W +: DATA_W];
                end
            end
        end
    endgenerate

endmodule