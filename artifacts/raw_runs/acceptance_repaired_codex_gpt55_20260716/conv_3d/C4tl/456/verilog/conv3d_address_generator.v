`timescale 1ns/1ps

module conv3d_address_generator #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter H = 64,
    parameter W = 64,
    parameter ADDR_W = 15
) (
    input  [ADDR_W-1:0] x_pos,
    input  [ADDR_W-1:0] y_pos,
    input  [ADDR_W-1:0] z_pos,
    output reg [K1*K2*K3*ADDR_W-1:0] tap_addrs
);

    integer dz;
    integer dy;
    integer dx;
    integer tap;

    integer tap_x;
    integer tap_y;
    integer tap_z;
    integer addr;

    always @* begin
        tap_addrs = {K1*K2*K3*ADDR_W{1'b0}};
        tap = 0;

        for (dz = 0; dz < K1; dz = dz + 1) begin
            for (dy = 0; dy < K2; dy = dy + 1) begin
                for (dx = 0; dx < K3; dx = dx + 1) begin
                    tap_z = z_pos - (K1 - 1 - dz);
                    tap_y = y_pos - (K2 - 1 - dy);
                    tap_x = x_pos - (K3 - 1 - dx);

                    addr = (tap_z * H * W) + (tap_y * W) + tap_x;

                    tap_addrs[tap*ADDR_W +: ADDR_W] = addr[ADDR_W-1:0];
                    tap = tap + 1;
                end
            end
        end
    end

endmodule