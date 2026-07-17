`timescale 1ns/1ps

module conv3d_window_addresses #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter ADDR_W = 32
) (
    input  [31:0] d,
    input  [31:0] h,
    input  [31:0] w,
    output reg [K1*K2*K3*ADDR_W-1:0] addrs
);

    integer kd;
    integer kh;
    integer kw;
    integer idx;

    reg [ADDR_W-1:0] ad;
    reg [ADDR_W-1:0] ah;
    reg [ADDR_W-1:0] aw;
    reg [ADDR_W-1:0] linear;

    always @* begin
        addrs = {K1*K2*K3*ADDR_W{1'b0}};
        idx = 0;

        if ((d >= (K1 - 1)) && (h >= (K2 - 1)) && (w >= (K3 - 1))) begin
            for (kd = 0; kd < K1; kd = kd + 1) begin
                for (kh = 0; kh < K2; kh = kh + 1) begin
                    for (kw = 0; kw < K3; kw = kw + 1) begin
                        ad = d - (K1 - 1) + kd;
                        ah = h - (K2 - 1) + kh;
                        aw = w - (K3 - 1) + kw;

                        linear = (ad * H * W) + (ah * W) + aw;

                        addrs[idx*ADDR_W +: ADDR_W] = linear;
                        idx = idx + 1;
                    end
                end
            end
        end
    end

endmodule