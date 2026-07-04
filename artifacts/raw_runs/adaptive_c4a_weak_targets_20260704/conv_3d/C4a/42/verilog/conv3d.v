`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output [DATA_W+LOG_KW-1:0] voxel_out,
    output valid_out,
    output done
);

    localparam N = D * H * W;
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;

    reg [DATA_W-1:0] volume [0:N-1];
    reg [31:0] wr_count;
    reg valid_r;
    reg done_r;
    reg [OUT_W-1:0] out_r;

    wire [31:0] z_pos;
    wire [31:0] y_pos;
    wire [31:0] x_pos;
    wire window_ok;
    wire [OUT_W-1:0] mac_out;

    reg [KW*DATA_W-1:0] window_flat;

    integer i;
    integer kz;
    integer ky;
    integer kx;
    integer tap;
    integer vz;
    integer vy;
    integer vx;
    integer vindex;

    conv3d_coord_calc #(
        .H(H),
        .W(W)
    ) u_coord (
        .linear_index(wr_count),
        .z(z_pos),
        .y(y_pos),
        .x(x_pos)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W)
    ) u_valid (
        .z(z_pos),
        .y(y_pos),
        .x(x_pos),
        .valid(window_ok)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .result(mac_out)
    );

    always @* begin
        window_flat = {KW*DATA_W{1'b0}};
        if (window_ok) begin
            tap = 0;
            for (kz = 0; kz < K1; kz = kz + 1) begin
                for (ky = 0; ky < K2; ky = ky + 1) begin
                    for (kx = 0; kx < K3; kx = kx + 1) begin
                        vz = z_pos - (K1 - 1) + kz;
                        vy = y_pos - (K2 - 1) + ky;
                        vx = x_pos - (K3 - 1) + kx;
                        vindex = (vz * H * W) + (vy * W) + vx;

                        if (vindex == wr_count)
                            window_flat[tap*DATA_W +: DATA_W] = voxel_in;
                        else if (vindex >= 0 && vindex < N)
                            window_flat[tap*DATA_W +: DATA_W] = volume[vindex];
                        else
                            window_flat[tap*DATA_W +: DATA_W] = {DATA_W{1'b0}};

                        tap = tap + 1;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            wr_count <= 0;
            valid_r <= 1'b0;
            done_r <= 1'b0;
            out_r <= {OUT_W{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                volume[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_r <= 1'b0;
            done_r <= 1'b0;

            if (valid_in) begin
                if (wr_count < N)
                    volume[wr_count] <= voxel_in;

                out_r <= window_ok ? mac_out : {OUT_W{1'b0}};
                valid_r <= window_ok;
                done_r <= last_in;

                if (last_in)
                    wr_count <= 0;
                else if (wr_count == N-1)
                    wr_count <= 0;
                else
                    wr_count <= wr_count + 1;
            end
        end
    end

    assign voxel_out = out_r;
    assign valid_out = valid_r;
    assign done = done_r;

endmodule