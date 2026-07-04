`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] sample_count,
    input         valid_in,
    input         last_in,
    output        window_valid,
    output        done
);

    localparam [31:0] TOTAL      = D * H * W;
    localparam [31:0] PLANE_SIZE = H * W;
    localparam [31:0] FIRST_VALID =
        (K1 - 1) * PLANE_SIZE +
        (K2 - 1) * W +
        (K3 - 1);

    wire [31:0] x;
    wire [31:0] y;
    wire [31:0] z;

    assign x = sample_count % W;
    assign y = (sample_count / W) % H;
    assign z = sample_count / PLANE_SIZE;

    assign window_valid = valid_in &&
                          (sample_count < TOTAL) &&
                          (K1 <= D) &&
                          (K2 <= H) &&
                          (K3 <= W) &&
                          (sample_count >= FIRST_VALID) &&
                          (x >= (K3 - 1)) &&
                          (y >= (K2 - 1)) &&
                          (z >= (K1 - 1));

    assign done = valid_in && last_in;

endmodule