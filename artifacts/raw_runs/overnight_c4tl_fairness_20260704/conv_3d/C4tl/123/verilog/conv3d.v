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
    localparam WIN_ELEMS = K1 * K2 * K3;
    localparam WIN_W = WIN_ELEMS * DATA_W;

    reg [DATA_W-1:0] volume_buffer [0:N-1];

    reg [31:0] input_count;
    wire [31:0] z_pos;
    wire [31:0] y_pos;
    wire [31:0] x_pos;
    wire window_is_valid;

    reg [WIN_W-1:0] window_flat;
    wire [OUT_W-1:0] mac_value;
    wire [OUT_W-1:0] selected_value;

    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    integer d_idx;
    integer h_idx;
    integer w_idx;
    integer flat_idx;
    integer mem_idx;
    integer wz;
    integer wy;
    integer wx;

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_coords #(
        .H(H),
        .W(W)
    ) u_coords (
        .linear_index(input_count),
        .z(z_pos),
        .y(y_pos),
        .x(x_pos)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3)
    ) u_window_valid (
        .z(z_pos),
        .y(y_pos),
        .x(x_pos),
        .valid(window_is_valid)
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
        .result(mac_value)
    );

    conv3d_output_select #(
        .OUT_W(OUT_W)
    ) u_output_select (
        .window_valid(window_is_valid),
        .mac_value(mac_value),
        .selected_value(selected_value)
    );

    always @(*) begin
        window_flat = {WIN_W{1'b0}};

        for (d_idx = 0; d_idx < K1; d_idx = d_idx + 1) begin
            for (h_idx = 0; h_idx < K2; h_idx = h_idx + 1) begin
                for (w_idx = 0; w_idx < K3; w_idx = w_idx + 1) begin
                    flat_idx = ((d_idx * K2 * K3) + (h_idx * K3) + w_idx) * DATA_W;

                    if (window_is_valid) begin
                        wz = z_pos - (K1 - 1) + d_idx;
                        wy = y_pos - (K2 - 1) + h_idx;
                        wx = x_pos - (K3 - 1) + w_idx;
                        mem_idx = (wz * H * W) + (wy * W) + wx;

                        if (mem_idx == input_count)
                            window_flat[flat_idx +: DATA_W] = voxel_in;
                        else
                            window_flat[flat_idx +: DATA_W] = volume_buffer[mem_idx];
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            input_count <= 0;
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            done_r <= 1'b0;
            valid_out_r <= 1'b0;
            voxel_out_r <= {OUT_W{1'b0}};

            if (valid_in) begin
                volume_buffer[input_count] <= voxel_in;
                voxel_out_r <= selected_value;
                valid_out_r <= window_is_valid;
                done_r <= last_in;

                if (last_in)
                    input_count <= 0;
                else if (input_count == N - 1)
                    input_count <= 0;
                else
                    input_count <= input_count + 1;
            end
        end
    end

endmodule