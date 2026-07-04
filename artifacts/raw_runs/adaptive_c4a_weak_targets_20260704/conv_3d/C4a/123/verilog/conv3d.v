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
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ACC_W = (2*DATA_W) + LOG_KW + 2;
    localparam KTOTAL = K1 * K2 * K3;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [31:0] in_count;

    wire [31:0] cur_z;
    wire [31:0] cur_y;
    wire [31:0] cur_x;
    wire window_valid;
    wire [KTOTAL*DATA_W-1:0] window_flat;
    wire [ACC_W-1:0] mac_full;
    wire [OUT_W-1:0] mac_trunc;

    reg [KTOTAL*DATA_W-1:0] window_flat_r;
    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    integer i;
    integer dz;
    integer dy;
    integer dx;
    integer tap;
    integer addr;
    integer iz;
    integer iy;
    integer ix;

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_coord #(
        .D(D),
        .H(H),
        .W(W)
    ) u_coord (
        .index(in_count),
        .z(cur_z),
        .y(cur_y),
        .x(cur_x)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3)
    ) u_window_valid (
        .z(cur_z),
        .y(cur_y),
        .x(cur_x),
        .valid(window_valid)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(window_flat),
        .kernel(kernel),
        .acc(mac_full)
    );

    conv3d_output_cast #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_cast (
        .in_value(mac_full),
        .out_value(mac_trunc)
    );

    assign window_flat = window_flat_r;

    always @* begin
        window_flat_r = {KTOTAL*DATA_W{1'b0}};
        tap = 0;

        for (dz = 0; dz < K1; dz = dz + 1) begin
            for (dy = 0; dy < K2; dy = dy + 1) begin
                for (dx = 0; dx < K3; dx = dx + 1) begin
                    iz = cur_z - (K1 - 1 - dz);
                    iy = cur_y - (K2 - 1 - dy);
                    ix = cur_x - (K3 - 1 - dx);
                    addr = (iz * H * W) + (iy * W) + ix;

                    if (window_valid) begin
                        if ((dz == K1-1) && (dy == K2-1) && (dx == K3-1)) begin
                            window_flat_r[tap*DATA_W +: DATA_W] = voxel_in;
                        end else begin
                            window_flat_r[tap*DATA_W +: DATA_W] = volume_mem[addr];
                        end
                    end else begin
                        window_flat_r[tap*DATA_W +: DATA_W] = {DATA_W{1'b0}};
                    end

                    tap = tap + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                volume_mem[i] <= {DATA_W{1'b0}};
            end
        end else begin
            done_r <= 1'b0;
            valid_out_r <= 1'b0;

            if (valid_in) begin
                volume_mem[in_count] <= voxel_in;
                voxel_out_r <= window_valid ? mac_trunc : {OUT_W{1'b0}};
                valid_out_r <= window_valid;
                done_r <= last_in;

                if (last_in) begin
                    in_count <= 0;
                end else if (in_count == N-1) begin
                    in_count <= 0;
                end else begin
                    in_count <= in_count + 1;
                end
            end
        end
    end

endmodule