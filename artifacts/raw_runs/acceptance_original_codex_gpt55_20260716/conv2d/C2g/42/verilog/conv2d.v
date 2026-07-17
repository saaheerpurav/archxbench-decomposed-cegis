module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         pixel_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = OUT_W + 8;

    assign valid_out = ~rst;

    integer r;
    integer row;
    integer col;

    reg [DATA_W-1:0] linebuf0 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] linebuf1 [0:IMG_WIDTH-1];

    reg [DATA_W-1:0] p00, p01, p02;
    reg [DATA_W-1:0] p10, p11, p12;
    reg [DATA_W-1:0] p20, p21, p22;

    reg [DATA_W-1:0] tap0;
    reg [DATA_W-1:0] tap1;

    reg [DATA_W-1:0] n00, n01, n02;
    reg [DATA_W-1:0] n10, n11, n12;
    reg [DATA_W-1:0] n20, n21, n22;

    reg [ACC_W-1:0] acc;

    always @(*) begin
        tap0 = linebuf0[col];
        tap1 = linebuf1[col];

        if (col == 0) begin
            n00 = 0;
            n01 = 0;
            n02 = (row < 2) ? 0 : tap1;

            n10 = 0;
            n11 = 0;
            n12 = (row < 1) ? 0 : tap0;

            n20 = 0;
            n21 = 0;
            n22 = pixel_in;
        end else begin
            n00 = p01;
            n01 = p02;
            n02 = (row < 2) ? 0 : tap1;

            n10 = p11;
            n11 = p12;
            n12 = (row < 1) ? 0 : tap0;

            n20 = p21;
            n21 = p22;
            n22 = pixel_in;
        end

        acc = 0;
        acc = acc + n00 + (n01 << 1) + n02;
        acc = acc + (n10 << 1) + (n11 << 2) + (n12 << 1);
        acc = acc + n20 + (n21 << 1) + n22;
    end

    assign pixel_out = acc[OUT_W+3:4];

    always @(posedge clk) begin
        if (rst) begin
            row <= 0;
            col <= 0;

            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            for (r = 0; r < IMG_WIDTH; r = r + 1) begin
                linebuf0[r] <= 0;
                linebuf1[r] <= 0;
            end
        end else begin
            p00 <= n00; p01 <= n01; p02 <= n02;
            p10 <= n10; p11 <= n11; p12 <= n12;
            p20 <= n20; p21 <= n21; p22 <= n22;

            linebuf0[col] <= pixel_in;
            linebuf1[col] <= tap0;

            if (col == IMG_WIDTH-1) begin
                col <= 0;
                row <= row + 1;
            end else begin
                col <= col + 1;
            end
        end
    end

endmodule