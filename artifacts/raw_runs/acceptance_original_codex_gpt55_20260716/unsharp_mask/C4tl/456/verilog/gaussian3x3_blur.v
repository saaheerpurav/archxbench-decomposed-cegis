module gaussian3x3_blur #(
    parameter PIXEL_W = 8
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output [PIXEL_W-1:0] blur
);

    wire [PIXEL_W+3:0] p00_ext = {{4{1'b0}}, p00};
    wire [PIXEL_W+3:0] p01_ext = {{4{1'b0}}, p01};
    wire [PIXEL_W+3:0] p02_ext = {{4{1'b0}}, p02};
    wire [PIXEL_W+3:0] p10_ext = {{4{1'b0}}, p10};
    wire [PIXEL_W+3:0] p11_ext = {{4{1'b0}}, p11};
    wire [PIXEL_W+3:0] p12_ext = {{4{1'b0}}, p12};
    wire [PIXEL_W+3:0] p20_ext = {{4{1'b0}}, p20};
    wire [PIXEL_W+3:0] p21_ext = {{4{1'b0}}, p21};
    wire [PIXEL_W+3:0] p22_ext = {{4{1'b0}}, p22};

    wire [PIXEL_W+3:0] sum;

    assign sum = p00_ext + (p01_ext << 1) + p02_ext
               + (p10_ext << 1) + (p11_ext << 2) + (p12_ext << 1)
               + p20_ext + (p21_ext << 1) + p22_ext;

    assign blur = sum[PIXEL_W+3:4];

endmodule