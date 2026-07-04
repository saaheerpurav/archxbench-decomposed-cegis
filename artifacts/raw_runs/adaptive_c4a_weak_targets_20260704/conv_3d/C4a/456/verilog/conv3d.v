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

    localparam OUT_W = DATA_W + LOG_KW;
    localparam N = D * H * W;
    localparam HIST_W = (N > 1) ? ((N-1) * DATA_W) : DATA_W;
    localparam SAMPLE_W = N * DATA_W;
    localparam WIN_W = K1 * K2 * K3 * DATA_W;

    reg [HIST_W-1:0] history;
    reg [31:0] x_pos;
    reg [31:0] y_pos;
    reg [31:0] z_pos;
    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    wire [SAMPLE_W-1:0] samples;
    wire [WIN_W-1:0] window;
    wire coord_valid;
    wire [OUT_W-1:0] mac_result;

    assign samples = {history, voxel_in};
    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_window_select #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .DATA_W(DATA_W)
    ) u_window_select (
        .samples(samples),
        .window(window)
    );

    conv3d_coord_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_coord_valid (
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .valid_coord(coord_valid)
    );

    conv3d_mac #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_mac (
        .window(window),
        .kernel(kernel),
        .result(mac_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            history <= {HIST_W{1'b0}};
            x_pos <= 0;
            y_pos <= 0;
            z_pos <= 0;
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            done_r <= 1'b0;

            if (valid_in) begin
                if (N > 1)
                    history <= {history[HIST_W-DATA_W-1:0], voxel_in};

                voxel_out_r <= coord_valid ? mac_result : {OUT_W{1'b0}};
                valid_out_r <= coord_valid;
                done_r <= last_in;

                if (last_in) begin
                    x_pos <= 0;
                    y_pos <= 0;
                    z_pos <= 0;
                end else if (x_pos == W-1) begin
                    x_pos <= 0;
                    if (y_pos == H-1) begin
                        y_pos <= 0;
                        if (z_pos == D-1)
                            z_pos <= 0;
                        else
                            z_pos <= z_pos + 1;
                    end else begin
                        y_pos <= y_pos + 1;
                    end
                end else begin
                    x_pos <= x_pos + 1;
                end
            end else begin
                valid_out_r <= 1'b0;
            end
        end
    end

endmodule