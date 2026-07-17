`timescale 1ns/1ps

module conv3d_window_extract #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8
) (
    input [D*H*W*DATA_W-1:0] volume_flat,
    input [clog2(D)-1:0] d_idx,
    input [clog2(H)-1:0] h_idx,
    input [clog2(W)-1:0] w_idx,
    output reg [K1*K2*K3*DATA_W-1:0] window_flat
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
            if (clog2 < 1)
                clog2 = 1;
        end
    endfunction

    integer kd, kh, kw;
    integer src_d, src_h, src_w;
    integer src_index;
    integer win_index;

    always @* begin
        window_flat = {K1*K2*K3*DATA_W{1'b0}};

        for (kd = 0; kd < K1; kd = kd + 1) begin
            for (kh = 0; kh < K2; kh = kh + 1) begin
                for (kw = 0; kw < K3; kw = kw + 1) begin
                    src_d = d_idx - (K1 - 1 - kd);
                    src_h = h_idx - (K2 - 1 - kh);
                    src_w = w_idx - (K3 - 1 - kw);

                    win_index = (kd * K2 * K3) + (kh * K3) + kw;

                    if ((src_d >= 0) && (src_d < D) &&
                        (src_h >= 0) && (src_h < H) &&
                        (src_w >= 0) && (src_w < W)) begin
                        src_index = (src_d * H * W) + (src_h * W) + src_w;
                        window_flat[win_index*DATA_W +: DATA_W] =
                            volume_flat[src_index*DATA_W +: DATA_W];
                    end
                end
            end
        end
    end

endmodule