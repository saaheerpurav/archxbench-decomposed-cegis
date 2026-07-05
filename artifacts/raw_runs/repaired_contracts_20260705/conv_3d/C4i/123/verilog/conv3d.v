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
    localparam X_W = CLOG2(W);
    localparam Y_W = CLOG2(H);
    localparam Z_W = CLOG2(D);
    localparam K_TOTAL = K1 * K2 * K3;
    localparam MAC_W = (2 * DATA_W) + CLOG2(K_TOTAL + 1);

    reg [DATA_W*N-1:0] volume_flat;
    reg [ADDR_W-1:0] flat_index;
    reg [X_W-1:0] x_pos;
    reg [Y_W-1:0] y_pos;
    reg [Z_W-1:0] z_pos;

    wire [ADDR_W-1:0] next_flat_index;
    wire [X_W-1:0] next_x_pos;
    wire [Y_W-1:0] next_y_pos;
    wire [Z_W-1:0] next_z_pos;
    wire input_window_valid;
    wire [DATA_W*K_TOTAL-1:0] window_flat;
    wire [MAC_W-1:0] mac_sum;

    conv3d_coord_next #(
        .D(D), .H(H), .W(W)
    ) u_coord_next (
        .flat_index(flat_index),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .next_flat_index(next_flat_index),
        .next_x_pos(next_x_pos),
        .next_y_pos(next_y_pos),
        .next_z_pos(next_z_pos)
    );

    conv3d_window_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_window_valid (
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .valid_in(valid_in),
        .valid_window(input_window_valid)
    );

    conv3d_window_gen #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .DATA_W(DATA_W)
    ) u_window_gen (
        .volume_flat(volume_flat),
        .voxel_in(voxel_in),
        .write_index(flat_index),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .window_flat(window_flat)
    );

    conv3d_mac #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            volume_flat <= {DATA_W*N{1'b0}};
            flat_index <= {ADDR_W{1'b0}};
            x_pos <= {X_W{1'b0}};
            y_pos <= {Y_W{1'b0}};
            z_pos <= {Z_W{1'b0}};
            voxel_out <= {(DATA_W+LOG_KW){1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (valid_in) begin
                volume_flat[flat_index*DATA_W +: DATA_W] <= voxel_in;
                voxel_out <= mac_sum[DATA_W+LOG_KW-1:0];
                valid_out <= input_window_valid;
                done <= last_in;

                flat_index <= next_flat_index;
                x_pos <= next_x_pos;
                y_pos <= next_y_pos;
                z_pos <= next_z_pos;
            end
        end
    end

endmodule