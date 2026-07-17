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

    function integer CLOG2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (CLOG2 = 0; v > 0; CLOG2 = CLOG2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam N = D * H * W;
    localparam ADDR_W = CLOG2(N);
    localparam K_TOTAL = K1 * K2 * K3;
    localparam SUM_W = DATA_W + LOG_KW;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [ADDR_W-1:0] write_addr;
    reg [ADDR_W-1:0] x_pos;
    reg [ADDR_W-1:0] y_pos;
    reg [ADDR_W-1:0] z_pos;

    wire window_valid;
    wire [K_TOTAL*ADDR_W-1:0] tap_addrs;
    wire [K_TOTAL*DATA_W-1:0] tap_voxels;
    wire [SUM_W-1:0] mac_sum;

    genvar t;
    generate
        for (t = 0; t < K_TOTAL; t = t + 1) begin : TAP_READS
            wire [ADDR_W-1:0] tap_addr;
            assign tap_addr = tap_addrs[t*ADDR_W +: ADDR_W];
            assign tap_voxels[t*DATA_W +: DATA_W] =
                (tap_addr == write_addr) ? voxel_in : volume_mem[tap_addr];
        end
    endgenerate

    conv3d_window_control #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .ADDR_W(ADDR_W)
    ) u_window_control (
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .window_valid(window_valid)
    );

    conv3d_address_generator #(
        .K1(K1), .K2(K2), .K3(K3),
        .H(H), .W(W),
        .ADDR_W(ADDR_W)
    ) u_address_generator (
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .tap_addrs(tap_addrs)
    );

    conv3d_mac_array #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .SUM_W(SUM_W)
    ) u_mac_array (
        .tap_voxels(tap_voxels),
        .kernel(kernel),
        .sum_out(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            write_addr <= {ADDR_W{1'b0}};
            x_pos <= {ADDR_W{1'b0}};
            y_pos <= {ADDR_W{1'b0}};
            z_pos <= {ADDR_W{1'b0}};
            voxel_out <= {SUM_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (valid_in) begin
                volume_mem[write_addr] <= voxel_in;
                voxel_out <= mac_sum;
                valid_out <= window_valid;
                done <= last_in;

                if (write_addr == N-1) begin
                    write_addr <= {ADDR_W{1'b0}};
                    x_pos <= {ADDR_W{1'b0}};
                    y_pos <= {ADDR_W{1'b0}};
                    z_pos <= {ADDR_W{1'b0}};
                end else begin
                    write_addr <= write_addr + 1'b1;

                    if (x_pos == W-1) begin
                        x_pos <= {ADDR_W{1'b0}};
                        if (y_pos == H-1) begin
                            y_pos <= {ADDR_W{1'b0}};
                            z_pos <= z_pos + 1'b1;
                        end else begin
                            y_pos <= y_pos + 1'b1;
                        end
                    end else begin
                        x_pos <= x_pos + 1'b1;
                    end
                end
            end
        end
    end

endmodule