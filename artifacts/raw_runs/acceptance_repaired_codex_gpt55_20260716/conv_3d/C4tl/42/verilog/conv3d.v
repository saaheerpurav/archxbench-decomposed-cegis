`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 5
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output reg [DATA_W+LOG_KW-1:0] voxel_out,
    output reg valid_out,
    output reg done
);

    localparam N = D * H * W;
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ADDR_W = 16;

    reg [DATA_W-1:0] volume_buffer [0:N-1];
    reg [ADDR_W-1:0] write_idx;
    reg [DATA_W*KW-1:0] window_reg;
    reg valid_pipe;
    reg done_pipe;

    wire [ADDR_W-1:0] z_pos;
    wire [ADDR_W-1:0] y_pos;
    wire [ADDR_W-1:0] x_pos;
    wire window_valid;
    wire [OUT_W-1:0] mac_sum;

    integer i;
    integer dz;
    integer dy;
    integer dx;
    integer tap;
    integer addr;

    conv3d_coord_decode #(
        .D(D), .H(H), .W(W), .K1(K1), .K2(K2), .K3(K3), .ADDR_W(ADDR_W)
    ) u_coord_decode (
        .index(write_idx),
        .z_pos(z_pos),
        .y_pos(y_pos),
        .x_pos(x_pos),
        .window_valid(window_valid)
    );

    conv3d_mac #(
        .K1(K1), .K2(K2), .K3(K3), .DATA_W(DATA_W), .LOG_KW(LOG_KW)
    ) u_mac (
        .window(window_reg),
        .kernel(kernel),
        .sum(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            write_idx <= {ADDR_W{1'b0}};
            window_reg <= {(DATA_W*KW){1'b0}};
            valid_pipe <= 1'b0;
            done_pipe <= 1'b0;
            voxel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;

            for (i = 0; i < N; i = i + 1) begin
                volume_buffer[i] <= {DATA_W{1'b0}};
            end
        end else begin
            voxel_out <= mac_sum;
            valid_out <= valid_pipe;
            done <= done_pipe;

            valid_pipe <= 1'b0;
            done_pipe <= 1'b0;

            if (valid_in) begin
                volume_buffer[write_idx] <= voxel_in;

                tap = 0;
                for (dz = 0; dz < K1; dz = dz + 1) begin
                    for (dy = 0; dy < K2; dy = dy + 1) begin
                        for (dx = 0; dx < K3; dx = dx + 1) begin
                            addr = ((z_pos - (K1 - 1 - dz)) * H * W) +
                                   ((y_pos - (K2 - 1 - dy)) * W) +
                                   (x_pos - (K3 - 1 - dx));

                            if (window_valid) begin
                                if (addr == write_idx)
                                    window_reg[tap*DATA_W +: DATA_W] <= voxel_in;
                                else
                                    window_reg[tap*DATA_W +: DATA_W] <= volume_buffer[addr];
                            end else begin
                                window_reg[tap*DATA_W +: DATA_W] <= {DATA_W{1'b0}};
                            end

                            tap = tap + 1;
                        end
                    end
                end

                valid_pipe <= window_valid;
                done_pipe <= last_in;

                if (last_in || write_idx == N-1)
                    write_idx <= {ADDR_W{1'b0}};
                else
                    write_idx <= write_idx + 1'b1;
            end
        end
    end

endmodule