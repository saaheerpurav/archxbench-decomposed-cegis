`timescale 1ns/1ps

module conv3d_index_decode #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] linear_idx,
    output [31:0] d,
    output [31:0] h,
    output [31:0] w
);

    localparam [31:0] W_CONST  = W;
    localparam [31:0] H_CONST  = H;
    localparam [31:0] HW_CONST = H * W;

    assign d = linear_idx / HW_CONST;
    assign h = (linear_idx / W_CONST) % H_CONST;
    assign w = linear_idx % W_CONST;

endmodule