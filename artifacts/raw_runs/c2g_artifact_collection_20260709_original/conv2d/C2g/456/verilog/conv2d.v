module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        pixel_in,
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] pixel_out
);

    localparam OUT_W      = DATA_W + GAIN_W;
    localparam ACC_W      = DATA_W + GAIN_W + 8;
    localparam IMG_PIXELS = IMG_WIDTH * IMG_WIDTH;

    reg [DATA_W-1:0] image [0:IMG_PIXELS-1];

    reg [31:0] pix_count;
    integer i;

    integer row;
    integer col;
    integer kr;
    integer kc;
    integer rr;
    integer cc;
    integer idx;

    reg [ACC_W-1:0] acc;

    function [3:0] coeff3x3;
        input integer r;
        input integer c;
        begin
            if (r == 0 && c == 0) coeff3x3 = 4'd1;
            else if (r == 0 && c == 1) coeff3x3 = 4'd2;
            else if (r == 0 && c == 2) coeff3x3 = 4'd1;
            else if (r == 1 && c == 0) coeff3x3 = 4'd2;
            else if (r == 1 && c == 1) coeff3x3 = 4'd4;
            else if (r == 1 && c == 2) coeff3x3 = 4'd2;
            else if (r == 2 && c == 0) coeff3x3 = 4'd1;
            else if (r == 2 && c == 1) coeff3x3 = 4'd2;
            else if (r == 2 && c == 2) coeff3x3 = 4'd1;
            else coeff3x3 = 4'd0;
        end
    endfunction

    always @(*) begin
        acc = {ACC_W{1'b0}};

        row = pix_count / IMG_WIDTH;
        col = pix_count % IMG_WIDTH;

        for (kr = 0; kr < 3; kr = kr + 1) begin
            for (kc = 0; kc < 3; kc = kc + 1) begin
                rr = row + kr - 1;
                cc = col + kc - 1;

                if (rr >= 0 && rr < IMG_WIDTH && cc >= 0 && cc < IMG_WIDTH) begin
                    idx = rr * IMG_WIDTH + cc;

                    if (idx == pix_count)
                        acc = acc + pixel_in * coeff3x3(kr, kc);
                    else if (idx < pix_count)
                        acc = acc + image[idx] * coeff3x3(kr, kc);
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b1;
            pixel_out <= {OUT_W{1'b0}};
            pix_count <= 0;

            for (i = 0; i < IMG_PIXELS; i = i + 1)
                image[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b1;

            if (valid_in) begin
                image[pix_count] <= pixel_in;
                pixel_out <= acc[OUT_W-1:0];

                if (pix_count < IMG_PIXELS - 1)
                    pix_count <= pix_count + 1;
            end
        end
    end

endmodule